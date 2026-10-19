//
//  FirebaseCallSignalingHandler.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Combine
import FirebaseFirestore

// MARK: - FirebaseCallSignalingHandler

/// Production-ready Firebase signaling transport backed by Firestore real-time listeners.
/// Coordinates WebRTC call signaling events across devices.
final class FirebaseCallSignalingHandler: CallSignalingHandlerProtocol, @unchecked Sendable {

    // MARK: - Singleton

    static let shared = FirebaseCallSignalingHandler()

    // MARK: - State & Publishers

    private let incomingSignalSubject = PassthroughSubject<CallSignal, Never>()
    var incomingSignalPublisher: AnyPublisher<CallSignal, Never> {
        incomingSignalSubject.eraseToAnyPublisher()
    }

    private(set) var isConnected: Bool = false
    private let logger = AppLogger.network
    private let lock = NSLock()

    // In-memory ledger of signals exchanged
    private var signalHistory: [CallSignal] = []
    private var processedSignalIds = Set<String>()
    private var signalingListener: ListenerRegistration?
    private var connectTimestamp: Double = 0

    // MARK: - Init

    init() {}

    deinit {
        disconnect()
    }

    // MARK: - Lifecycle
 
    func connect() async throws {
        resetConnectionState()

        logger.info("FirebaseCallSignalingHandler connecting to Firestore signaling collection...")

        let db = Firestore.firestore()
        let currentUserId = resolvedCurrentUserId()

        // Listen for signals directed to the current user
        let listener = db.collection("call_signals")
            .whereField("toUserId", isEqualTo: currentUserId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    self.logger.notice("Signaling listener warning: \(error.localizedDescription)")
                    return
                }
                guard let snapshot = snapshot else { return }
                self.handleSnapshotChanges(snapshot.documentChanges)
            }

        setSignalingListener(listener)

        logger.info("FirebaseCallSignalingHandler connected for toUserId: \(currentUserId)")
    }

    private func resetConnectionState() {
        lock.lock()
        isConnected = true
        connectTimestamp = Date().timeIntervalSince1970 - 5.0
        signalingListener?.remove()
        signalingListener = nil
        lock.unlock()
    }

    private func setSignalingListener(_ listener: ListenerRegistration) {
        lock.lock()
        signalingListener = listener
        lock.unlock()
    }

    func disconnect() {
        lock.lock()
        isConnected = false
        signalingListener?.remove()
        signalingListener = nil
        lock.unlock()

        logger.info("FirebaseCallSignalingHandler disconnected from signaling collection.")
    }

    // MARK: - Send Signal

    func send(signal: CallSignal) async throws {
        appendSignalHistory(signal)
        logger.info("FirebaseCallSignalingHandler sending outgoing signal: \(String(describing: signal))")

        let signalDocId = "sig_\(UUID().uuidString.prefix(12))"
        recordProcessedSignalId(signalDocId)

        var dict = Self.signalToDict(signal)
        dict["id"] = signalDocId
        dict["timestamp"] = Date().timeIntervalSince1970

        let db = Firestore.firestore()

        // 1. Root-level collection for fast inbox query by toUserId
        try? await db.collection("call_signals").document(signalDocId).setData(dict)

        // 2. Hierarchical call subcollection `calls/{callId}/signals`
        try? await db.collection("calls")
            .document(signal.callId)
            .collection("signals")
            .document(signalDocId)
            .setData(dict)
    }

    private func recordProcessedSignalId(_ signalDocId: String) {
        lock.lock()
        processedSignalIds.insert(signalDocId)
        lock.unlock()
    }

    // MARK: - Ingestion / Remote Reception

    /// Ingests a signal received from Firebase Firestore snapshot listener or RTDB child event.
    func receiveRemoteSignal(_ signal: CallSignal) {
        logger.info("FirebaseCallSignalingHandler received remote signal: \(String(describing: signal))")
        incomingSignalSubject.send(signal)
    }

    /// Simulation utility for test benches and instant single-device testability.
    func simulateIncomingCall(fromUserId: String, name: String, hasVideo: Bool, toUserId: String? = nil) {
        let callId = UUID().uuidString
        let recipientId: String
        if let toUserId, !toUserId.isEmpty {
            recipientId = toUserId
        } else if Thread.isMainThread {
            recipientId = MainActor.assumeIsolated { SessionStore.shared.currentUserId }
        } else {
            recipientId = resolvedCurrentUserId()
        }
        let signal = CallSignal.callIncoming(
            callId: callId,
            fromUserId: fromUserId,
            toUserId: recipientId,
            callType: hasVideo ? .video : .audio,
            callerName: name,
            avatarURL: nil
        )
        receiveRemoteSignal(signal)
    }

    // MARK: - Private Snapshot Processing

    private func handleSnapshotChanges(_ changes: [DocumentChange]) {
        for change in changes {
            guard change.type == .added else { continue }
            let doc = change.document
            let docId = doc.documentID

            lock.lock()
            if processedSignalIds.contains(docId) {
                lock.unlock()
                continue
            }
            processedSignalIds.insert(docId)
            let baseConnectTime = connectTimestamp
            lock.unlock()

            let data = doc.data()
            if let timestamp = data["timestamp"] as? Double, timestamp < baseConnectTime {
                // Ignore stale signals generated before connection
                continue
            }

            if let signal = Self.dictToSignal(data) {
                receiveRemoteSignal(signal)
            }
        }
    }

    private func resolvedCurrentUserId() -> String {
        let id = SessionStore.shared.currentUserId
        return id.isEmpty ? "current_user" : id
    }

    // MARK: - Synchronous Lock Helpers

    private func updateConnectedState(_ connected: Bool) {
        lock.lock()
        defer { lock.unlock() }
        isConnected = connected
    }

    private func appendSignalHistory(_ signal: CallSignal) {
        lock.lock()
        defer { lock.unlock() }
        signalHistory.append(signal)
    }

    // MARK: - Signal Serialization & Deserialization

    static func signalToDict(_ signal: CallSignal) -> [String: Any] {
        var dict: [String: Any] = [
            "callId": signal.callId,
            "fromUserId": signal.fromUserId,
            "toUserId": signal.toUserId
        ]

        switch signal {
        case .callInitiate(_, _, _, let callType):
            dict["signalType"] = "callInitiate"
            dict["callType"] = callType.rawValue

        case .callIncoming(_, _, _, let callType, let callerName, let avatarURL):
            dict["signalType"] = "callIncoming"
            dict["callType"] = callType.rawValue
            if let name = callerName {
                dict["callerName"] = name
            }
            if let avatar = avatarURL?.absoluteString {
                dict["avatarURL"] = avatar
            }

        case .callOffer(_, _, _, let sdp):
            dict["signalType"] = "callOffer"
            dict["sdp"] = sdp

        case .callAnswer(_, _, _, let sdp):
            dict["signalType"] = "callAnswer"
            dict["sdp"] = sdp

        case .callIceCandidate(_, _, _, let candidate, let sdpMid, let sdpMLineIndex):
            dict["signalType"] = "callIceCandidate"
            dict["candidate"] = candidate
            if let mid = sdpMid {
                dict["sdpMid"] = mid
            }
            if let mLineIndex = sdpMLineIndex {
                dict["sdpMLineIndex"] = mLineIndex
            }

        case .callHangup:
            dict["signalType"] = "callHangup"

        case .callReject:
            dict["signalType"] = "callReject"

        case .callBusy:
            dict["signalType"] = "callBusy"

        case .callRinging:
            dict["signalType"] = "callRinging"
        }

        return dict
    }

    static func dictToSignal(_ dict: [String: Any]) -> CallSignal? {
        guard let callId = dict["callId"] as? String,
              let fromUserId = dict["fromUserId"] as? String,
              let toUserId = dict["toUserId"] as? String,
              let signalType = dict["signalType"] as? String else {
            return nil
        }

        let rawCallType = dict["callType"] as? String ?? "audio"
        let callType: CallType = (rawCallType == "video") ? .video : .audio

        switch signalType {
        case "callInitiate":
            return .callInitiate(callId: callId, fromUserId: fromUserId, toUserId: toUserId, callType: callType)

        case "callIncoming":
            let callerName = dict["callerName"] as? String
            let avatarURL = (dict["avatarURL"] as? String).flatMap { URL(string: $0) }
            return .callIncoming(
                callId: callId,
                fromUserId: fromUserId,
                toUserId: toUserId,
                callType: callType,
                callerName: callerName,
                avatarURL: avatarURL
            )

        case "callOffer":
            let sdp = dict["sdp"] as? String ?? ""
            return .callOffer(callId: callId, fromUserId: fromUserId, toUserId: toUserId, sdp: sdp)

        case "callAnswer":
            let sdp = dict["sdp"] as? String ?? ""
            return .callAnswer(callId: callId, fromUserId: fromUserId, toUserId: toUserId, sdp: sdp)

        case "callIceCandidate":
            let candidate = dict["candidate"] as? String ?? ""
            let sdpMid = dict["sdpMid"] as? String
            let sdpMLineIndex = dict["sdpMLineIndex"] as? Int
            return .callIceCandidate(
                callId: callId,
                fromUserId: fromUserId,
                toUserId: toUserId,
                candidate: candidate,
                sdpMid: sdpMid,
                sdpMLineIndex: sdpMLineIndex
            )

        case "callHangup":
            return .callHangup(callId: callId, fromUserId: fromUserId, toUserId: toUserId)

        case "callReject":
            return .callReject(callId: callId, fromUserId: fromUserId, toUserId: toUserId)

        case "callBusy":
            return .callBusy(callId: callId, fromUserId: fromUserId, toUserId: toUserId)

        case "callRinging":
            return .callRinging(callId: callId, fromUserId: fromUserId, toUserId: toUserId)

        default:
            return nil
        }
    }
}
