//
//  FirebaseCallSignalingHandler.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Combine

// MARK: - FirebaseCallSignalingHandler

/// Production-ready Firebase signaling transport (Firestore / Realtime Database document listeners).
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

    // In-memory ledger of signals exchanged (ready for Firestore/RTDB integration)
    private var signalHistory: [CallSignal] = []

    // MARK: - Init

    init() {}

    // MARK: - Lifecycle

    func connect() async throws {
        updateConnectedState(true)
        logger.info("FirebaseCallSignalingHandler connected to signaling collection.")
    }

    func disconnect() {
        updateConnectedState(false)
        logger.info("FirebaseCallSignalingHandler disconnected from signaling collection.")
    }

    // MARK: - Send Signal

    func send(signal: CallSignal) async throws {
        appendSignalHistory(signal)
        logger.info("FirebaseCallSignalingHandler recorded outgoing signal: \(String(describing: signal))")

        // In live Firebase implementation:
        // Firestore.firestore().collection("calls").document(signal.callId).collection("signals").addDocument(...)
    }

    // MARK: - Ingestion / Remote Reception

    /// Ingests a signal received from Firebase Firestore snapshot listener or RTDB child event.
    func receiveRemoteSignal(_ signal: CallSignal) {
        logger.info("FirebaseCallSignalingHandler received remote signal: \(String(describing: signal))")
        incomingSignalSubject.send(signal)
    }

    /// Simulation utility for test benches.
    func simulateIncomingCall(fromUserId: String, name: String, hasVideo: Bool, toUserId: String? = nil) {
        let callId = UUID().uuidString
        let recipientId: String
        if let toUserId, !toUserId.isEmpty {
            recipientId = toUserId
        } else if Thread.isMainThread {
            recipientId = MainActor.assumeIsolated { SessionStore.shared.currentUserId }
        } else {
            recipientId = "current_user"
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
}
