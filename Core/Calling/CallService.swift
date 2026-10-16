//
//  CallService.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Combine
internal import CallKit

// MARK: - CallState

/// Finite state machine for a single call lifecycle.
enum CallState: Equatable, Sendable {
    case idle
    case initiating               // Outgoing: sending call_initiate
    case ringing                  // Outgoing: remote side is ringing
    case incomingRinging          // Incoming: showing CallKit UI, waiting user action
    case connecting               // Exchanging SDP offer/answer
    case connected                // Media flowing
    case reconnecting             // Temporary ICE disconnection
    case ending                   // Hangup sent, waiting cleanup
    case ended(CallEndReason)     // Terminal state

    var isActive: Bool {
        switch self {
        case .idle, .ended: return false
        default: return true
        }
    }
}

// MARK: - CallEndReason

enum CallEndReason: Equatable, Sendable {
    case localHangup
    case remoteHangup
    case rejected
    case busy
    case timeout
    case failed(String)
    case cancelled
}

// MARK: - CallServiceProtocol

protocol CallServiceProtocol: AnyObject, Sendable {
    var currentCallState: CallState { get }
    var callStatePublisher: AnyPublisher<CallState, Never> { get }
    var currentCall: ActiveCall? { get }

    func initiateCall(to userId: String, name: String, hasVideo: Bool) async throws
    func acceptIncomingCall() async throws
    func rejectIncomingCall() async throws
    func hangup() async throws
    func toggleMute() async throws
    func toggleSpeaker() async throws
    func upgradeToVideo() async throws
}

// MARK: - ActiveCall

/// Represents the currently active call with all metadata.
struct ActiveCall: Sendable {
    let id: String
    let uuid: UUID
    let remoteUserId: String
    let remoteName: String
    var hasVideo: Bool
    let isOutgoing: Bool
    let startedAt: Date
    var isMuted: Bool = false
    var isSpeakerOn: Bool = false
    var connectedAt: Date?
}

// MARK: - CallService

/// Coordinates WebSocket signaling, CallKit, and call state.
/// This is the single source of truth for the current call state.
///
/// Flow (outgoing):
///   idle → initiating → ringing → connecting → connected → ended
///
/// Flow (incoming):
///   idle → incomingRinging → connecting → connected → ended
///
@MainActor
final class CallService: CallServiceProtocol, @unchecked Sendable {

    static let shared = CallService()

    // MARK: - State

    private(set) var currentCallState: CallState = .idle {
        didSet {
            callStateSubject.send(currentCallState)
            logger.info("Call state: \(String(describing: currentCallState))")
        }
    }

    private(set) var currentCall: ActiveCall? {
        didSet {
            currentCallSubject.send(currentCall)
        }
    }

    private let callStateSubject = CurrentValueSubject<CallState, Never>(.idle)
    var callStatePublisher: AnyPublisher<CallState, Never> {
        callStateSubject.eraseToAnyPublisher()
    }

    private let currentCallSubject = CurrentValueSubject<ActiveCall?, Never>(nil)
    var currentCallPublisher: AnyPublisher<ActiveCall?, Never> {
        currentCallSubject.eraseToAnyPublisher()
    }

    // MARK: - Dependencies

    private let callManager: CallManager
    private var messageHandler: WebSocketMessageHandler?
    private let logger = AppLogger.general

    // MARK: - Timers

    private var ringTimeoutTask: Task<Void, Never>?
    private var autoAnswerTask: Task<Void, Never>?
    private let ringTimeoutSeconds: TimeInterval = 45

    // MARK: - Subscriptions

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    private init(
        callManager: CallManager? = nil,
        messageHandler: WebSocketMessageHandler? = nil
    ) {
        self.callManager = callManager ?? CallManager.shared
        self.messageHandler = messageHandler ?? DIContainer.shared.resolveOptional(WebSocketMessageHandler.self)
        subscribeToCallKitEvents()
        subscribeToSignaling()
    }

    /// For DI / testing
    static func create(
        callManager: CallManager,
        messageHandler: WebSocketMessageHandler
    ) -> CallService {
        let service = CallService(callManager: callManager, messageHandler: messageHandler)
        return service
    }

    func configure(messageHandler: WebSocketMessageHandler) {
        self.messageHandler = messageHandler
        cancellables.removeAll()
        subscribeToCallKitEvents()
        subscribeToSignaling()
    }

    // MARK: - Outgoing Call

    func initiateCall(to userId: String, name: String, hasVideo: Bool) async throws {
        guard currentCallState == .idle || !currentCallState.isActive else {
            throw CallServiceError.callAlreadyInProgress
        }

        let callId = UUID().uuidString
        let uuid = UUID()

        let call = ActiveCall(
            id: callId,
            uuid: uuid,
            remoteUserId: userId,
            remoteName: name,
            hasVideo: hasVideo,
            isOutgoing: true,
            startedAt: Date()
        )
        currentCall = call
        currentCallState = .initiating

        do {
            // Report to CallKit
            try await callManager.startOutgoingCall(
                uuid: uuid,
                callId: callId,
                remoteUserId: userId,
                remoteName: name,
                hasVideo: hasVideo
            )

            // Send call_initiate via WebSocket with fromUserId
            let currentUserId = SessionStore.shared.currentUserId
            try await messageHandler?.send(
                .callInitiate(
                    callId: callId,
                    fromUserId: currentUserId,
                    toUserId: userId,
                    callType: hasVideo ? .video : .audio
                )
            )

            currentCallState = .ringing
            callManager.reportOutgoingCallStartedConnecting(uuid: uuid)
            startRingTimeout()

            #if targetEnvironment(simulator)
            startSimulatorAutoAnswer(uuid: uuid)
            #else
            if AppConfig.shared.isMockAPI {
                startSimulatorAutoAnswer(uuid: uuid)
            }
            #endif
        } catch {
            logger.error("Failed to initiate call: \(error.localizedDescription)")
            cancelRingTimeout()
            currentCall = nil
            currentCallState = .idle
            try? await callManager.endCall(uuid: uuid)
            throw error
        }
    }

    // MARK: - Simulator Auto-Answer

    private func startSimulatorAutoAnswer(uuid: UUID) {
        autoAnswerTask?.cancel()
        autoAnswerTask = Task { [weak self] in
            // Ring for 3.0 seconds, then simulate partner answering
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard let self, self.currentCallState == .ringing, self.currentCall?.uuid == uuid else { return }

            self.logger.info("Simulator Auto-Answer: Partner picked up -> connecting")
            self.currentCallState = .connecting

            try? await Task.sleep(nanoseconds: 800_000_000)
            guard self.currentCallState == .connecting, self.currentCall?.uuid == uuid else { return }

            self.cancelRingTimeout()
            self.currentCall?.connectedAt = Date()
            self.currentCallState = .connected
            self.callManager.reportOutgoingCallConnected(uuid: uuid)
            self.logger.info("Simulator Auto-Answer: Connected successfully")
        }
    }

    // MARK: - Accept Incoming Call

    func acceptIncomingCall() async throws {
        guard currentCallState == .incomingRinging,
              let call = currentCall else {
            throw CallServiceError.noIncomingCall
        }

        cancelRingTimeout()
        currentCallState = .connecting

        // In production: create WebRTC peer connection, generate SDP answer
        // For now, send a placeholder answer signal
        let currentUserId = SessionStore.shared.currentUserId
        try await messageHandler?.send(
            .callAnswer(
                callId: call.id,
                fromUserId: currentUserId,
                toUserId: call.remoteUserId,
                sdp: "placeholder_sdp_answer"
            )
        )

        // Simulate connection established
        currentCallState = .connected
        currentCall?.connectedAt = Date()
        callManager.reportCallConnected(uuid: call.uuid, isOutgoing: false)
    }

    // MARK: - Reject Incoming Call

    func rejectIncomingCall() async throws {
        guard currentCallState == .incomingRinging,
              let call = currentCall else {
            throw CallServiceError.noIncomingCall
        }

        cancelRingTimeout()

        let currentUserId = SessionStore.shared.currentUserId
        try await messageHandler?.send(
            .callReject(
                callId: call.id,
                fromUserId: currentUserId,
                toUserId: call.remoteUserId
            )
        )

        callManager.reportCallEnded(uuid: call.uuid, reason: .declinedElsewhere)
        endCall(reason: .rejected)
    }

    // MARK: - Hangup

    func hangup() async throws {
        guard let call = currentCall, currentCallState.isActive else {
            throw CallServiceError.noActiveCall
        }

        currentCallState = .ending
        cancelRingTimeout()

        let callId = call.id
        let uuid = call.uuid
        let remoteUserId = call.remoteUserId
        let currentUserId = SessionStore.shared.currentUserId

        // Guaranteed local hangup cleanup: do not let network send error block CallKit/Audio cleanup
        do {
            try await messageHandler?.send(
                .callHangup(
                    callId: callId,
                    fromUserId: currentUserId,
                    toUserId: remoteUserId
                )
            )
        } catch {
            logger.notice("Failed to send hangup signal: \(error.localizedDescription)")
        }

        try? await callManager.endCall(uuid: uuid)
        endCall(reason: .localHangup)
    }

    // MARK: - Upgrade to Video

    func upgradeToVideo() async throws {
        guard var call = currentCall, currentCallState == .connected else {
            throw CallServiceError.noActiveCall
        }
        guard !call.hasVideo else { return }

        call.hasVideo = true
        currentCall = call

        let currentUserId = SessionStore.shared.currentUserId
        try? await messageHandler?.send(
            .callOffer(
                callId: call.id,
                fromUserId: currentUserId,
                toUserId: call.remoteUserId,
                sdp: "upgrade_to_video_renegotiation"
            )
        )
        logger.info("Call successfully upgraded to video for call \(call.id)")
    }

    // MARK: - Mute / Speaker

    func toggleMute() async throws {
        guard var call = currentCall else {
            throw CallServiceError.noActiveCall
        }

        call.isMuted.toggle()
        currentCall = call
        try await callManager.setMuted(uuid: call.uuid, muted: call.isMuted)
    }

    func toggleSpeaker() async throws {
        guard var call = currentCall else {
            throw CallServiceError.noActiveCall
        }

        call.isSpeakerOn.toggle()
        currentCall = call

        // Configure audio route
        let session = AVAudioSession.sharedInstance()
        do {
            if call.isSpeakerOn {
                try session.overrideOutputAudioPort(.speaker)
            } else {
                try session.overrideOutputAudioPort(.none)
            }
        } catch {
            logger.error("Failed to toggle speaker: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Incoming Call (from WebSocket/Push)

    /// Called when a call signal arrives (via WebSocket or VoIP push).
    func handleIncomingCall(signal: CallSignal, callerName: String, uuid: UUID? = nil) async {
        guard currentCallState == .idle || !currentCallState.isActive else {
            // Already in an active call — send busy
            let currentUserId = SessionStore.shared.currentUserId
            try? await messageHandler?.send(
                .callBusy(callId: signal.callId, fromUserId: currentUserId, toUserId: signal.fromUserId)
            )
            return
        }

        let callUUID = uuid ?? UUID()
        let call = ActiveCall(
            id: signal.callId,
            uuid: callUUID,
            remoteUserId: signal.fromUserId,
            remoteName: callerName,
            hasVideo: signal.callType == .video,
            isOutgoing: false,
            startedAt: Date()
        )
        currentCall = call
        currentCallState = .incomingRinging

        // If uuid was passed in (e.g. from VoIP push), CallKit was already reported by VoIPPushService.
        // Only report to CallKit if uuid == nil (e.g. incoming from in-app WebSocket signal).
        if uuid == nil {
            do {
                try await callManager.reportIncomingCall(
                    uuid: callUUID,
                    callId: signal.callId,
                    callerName: callerName,
                    callerUserId: signal.fromUserId,
                    hasVideo: signal.callType == .video
                )
            } catch {
                logger.error("Failed to report incoming call: \(error.localizedDescription)")
                endCall(reason: .failed(error.localizedDescription))
                return
            }
        }

        // Notify remote: we are ringing
        let currentUserId = SessionStore.shared.currentUserId
        try? await messageHandler?.send(
            .callRinging(callId: signal.callId, fromUserId: currentUserId, toUserId: signal.fromUserId)
        )

        // Present in-app call screen so user sees incoming call UI
        AppRouter.shared.present(
            fullScreen: .call(
                userId: signal.fromUserId,
                userName: callerName,
                hasVideo: signal.callType == .video
            )
        )

        startRingTimeout()
    }

    // MARK: - Simulate Incoming Call (Testing / Debug)

    func simulateIncomingCall(fromUserId: String, name: String, hasVideo: Bool) async {
        let signal = CallSignal(
            callId: UUID().uuidString,
            fromUserId: fromUserId,
            toUserId: SessionStore.shared.currentUserId,
            callType: hasVideo ? .video : .audio,
            sdp: nil,
            iceCandidate: nil,
            iceSdpMid: nil,
            iceSdpMLineIndex: nil,
            timestamp: Date()
        )
        await handleIncomingCall(signal: signal, callerName: name)
    }

    // MARK: - Private: End Call Cleanup

    private func endCall(reason: CallEndReason) {
        cancelRingTimeout()

        let endedCall = currentCall
        let remoteUserId = endedCall?.remoteUserId ?? ""
        let isOutgoing = endedCall?.isOutgoing ?? true
        let callerUserId = isOutgoing ? SessionStore.shared.currentUserId : remoteUserId
        let hasVideo = endedCall?.hasVideo ?? false
        var durationStr = "00:00"
        if let connectedAt = endedCall?.connectedAt {
            let elapsed = Int(Date().timeIntervalSince(connectedAt))
            let minutes = elapsed / 60
            let seconds = elapsed % 60
            if elapsed >= 3600 {
                let hours = elapsed / 3600
                let remMinutes = (elapsed % 3600) / 60
                durationStr = String(format: "%02d:%02d:%02d", hours, remMinutes, seconds)
            } else {
                durationStr = String(format: "%02d:%02d", minutes, seconds)
            }
        }

        currentCallState = .ended(reason)
        currentCall = nil

        // Post didEndCall notification for chat message recording
        if !remoteUserId.isEmpty {
            let reasonString: String
            switch reason {
            case .localHangup: reasonString = "localHangup"
            case .remoteHangup: reasonString = "remoteHangup"
            case .rejected: reasonString = "rejected"
            case .busy: reasonString = "busy"
            case .timeout: reasonString = "timeout"
            case .failed(let err): reasonString = "failed: \(err)"
            case .cancelled: reasonString = "cancelled"
            }

            NotificationCenter.default.post(
                name: .didEndCall,
                object: nil,
                userInfo: [
                    "remoteUserId": remoteUserId,
                    "callerUserId": callerUserId,
                    "isOutgoing": isOutgoing,
                    "hasVideo": hasVideo,
                    "duration": durationStr,
                    "reason": reasonString
                ]
            )
        }

        callManager.deactivateAudioSession()

        // Reset to idle after UI transition, without blocking new incoming calls
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if case .ended = self.currentCallState {
                self.currentCallState = .idle
            }
        }
    }

    // MARK: - Private: Ring Timeout

    private func startRingTimeout() {
        cancelRingTimeout()
        ringTimeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(45 * 1_000_000_000))
            guard let self, self.currentCallState == .ringing || self.currentCallState == .incomingRinging else { return }

            if let call = self.currentCall {
                self.callManager.reportCallEnded(uuid: call.uuid, reason: .unanswered)
            }
            self.endCall(reason: .timeout)
        }
    }

    private func cancelRingTimeout() {
        ringTimeoutTask?.cancel()
        ringTimeoutTask = nil
        autoAnswerTask?.cancel()
        autoAnswerTask = nil
    }

    // MARK: - Private: Subscribe to CallKit Events

    private func subscribeToCallKitEvents() {
        callManager.callEvents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                Task { @MainActor in
                    self.handleCallKitEvent(event)
                }
            }
            .store(in: &cancellables)
    }

    private func handleCallKitEvent(_ event: CallKitEvent) {
        switch event {
        case .answerCall:
            Task { try? await acceptIncomingCall() }

        case .endCall(let uuid):
            if currentCall?.uuid == uuid, currentCallState != .ending, !isEndedState {
                Task { try? await hangup() }
            }

        case .setMuted(_, let muted):
            currentCall?.isMuted = muted
            currentCallSubject.send(currentCall)

        case .audioSessionActivated:
            // WebRTC / Audio engine: activate audio track
            break

        case .audioSessionDeactivated:
            // WebRTC / Audio engine: deactivate audio track
            break

        case .providerDidReset:
            endCall(reason: .failed("Provider reset"))

        default:
            break
        }
    }

    private var isEndedState: Bool {
        if case .ended = currentCallState { return true }
        return false
    }

    // MARK: - Private: Subscribe to WebSocket Signaling

    private func subscribeToSignaling() {
        messageHandler?.callSignaling
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self else { return }
                Task { @MainActor in
                    self.handleSignalingMessage(message)
                }
            }
            .store(in: &cancellables)
    }

    private func handleSignalingMessage(_ message: WebSocketIncomingMessage) {
        switch message {
        case .callIncoming(let signal):
            Task { await handleIncomingCall(signal: signal, callerName: signal.fromUserId) }

        case .callOffer(let signal):
            // Received SDP offer — in production: set remote description
            logger.info("Received call offer for \(signal.callId)")
            if currentCallState == .connecting || currentCallState == .incomingRinging {
                // Store offer SDP for WebRTC peer connection
            }

        case .callAnswer(let signal):
            // Received SDP answer — in production: set remote description
            logger.info("Received call answer for \(signal.callId)")
            cancelRingTimeout()
            if currentCallState == .ringing || currentCallState == .connecting {
                currentCallState = .connected
                currentCall?.connectedAt = Date()
                if let uuid = currentCall?.uuid {
                    callManager.reportCallConnected(uuid: uuid, isOutgoing: true)
                }
            }

        case .callIceCandidate(let signal):
            // Received ICE candidate — in production: add to peer connection
            logger.info("Received ICE candidate for \(signal.callId)")

        case .callHangup(let callId, _):
            if currentCall?.id == callId {
                if let uuid = currentCall?.uuid {
                    callManager.reportCallEnded(uuid: uuid, reason: .remoteEnded)
                }
                endCall(reason: .remoteHangup)
            }

        case .callReject(let callId, _):
            if currentCall?.id == callId {
                if let uuid = currentCall?.uuid {
                    callManager.reportCallEnded(uuid: uuid, reason: .declinedElsewhere)
                }
                endCall(reason: .rejected)
            }

        case .callBusy(let callId, _):
            if currentCall?.id == callId {
                if let uuid = currentCall?.uuid {
                    callManager.reportCallEnded(uuid: uuid, reason: .unanswered)
                }
                endCall(reason: .busy)
            }

        case .callRinging(let callId, _):
            if currentCall?.id == callId, (currentCallState == .initiating || currentCallState == .ringing) {
                currentCallState = .ringing
            }

        default:
            break
        }
    }
}

// MARK: - CallServiceError

enum CallServiceError: LocalizedError {
    case callAlreadyInProgress
    case noActiveCall
    case noIncomingCall
    case signalingFailed(String)

    var errorDescription: String? {
        switch self {
        case .callAlreadyInProgress: return "A call is already in progress."
        case .noActiveCall:          return "No active call."
        case .noIncomingCall:        return "No incoming call to answer."
        case .signalingFailed(let msg): return "Signaling failed: \(msg)"
        }
    }
}

// MARK: - AVAudioSession import

import AVFoundation
