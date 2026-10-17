//
//  CallService.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Combine
internal import CallKit
import AVFoundation

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
    func initiateCall(to userId: String, name: String, avatarURL: URL?, hasVideo: Bool) async throws
    func acceptIncomingCall() async throws
    func rejectIncomingCall() async throws
    func hangup() async throws
    func toggleMute() async throws
    func toggleSpeaker() async throws
    func upgradeToVideo() async throws
    func setMuted(_ isMuted: Bool)
    func setSpeaker(_ isSpeaker: Bool)
    func flipCamera(isFront: Bool) async
    func toggleCamera(isOff: Bool) async
}

extension CallServiceProtocol {
    func initiateCall(to userId: String, name: String, hasVideo: Bool) async throws {
        try await initiateCall(to: userId, name: name, avatarURL: nil, hasVideo: hasVideo)
    }
}

// MARK: - ActiveCall

/// Represents the currently active call with all metadata.
struct ActiveCall: Sendable {
    let id: String
    let uuid: UUID
    let remoteUserId: String
    let remoteName: String
    var remoteAvatarURL: URL? = nil
    var hasVideo: Bool
    let isOutgoing: Bool
    let startedAt: Date
    var isMuted: Bool = false
    var isSpeakerOn: Bool = false
    var connectedAt: Date?
}

// MARK: - CallService

/// Coordinates signaling, CallKit, media pipeline, and call state.
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
    private(set) var signalingHandler: CallSignalingHandlerProtocol
    let mediaPipeline: CallMediaPipelineProtocol
    private let logger = AppLogger.general

    // MARK: - Timers

    private var ringTimeoutTask: Task<Void, Never>?
    private let ringTimeoutSeconds: TimeInterval = 45

    // MARK: - Subscriptions

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        callManager: CallManager? = nil,
        signalingHandler: CallSignalingHandlerProtocol? = nil,
        mediaPipeline: CallMediaPipelineProtocol? = nil
    ) {
        self.callManager = callManager ?? CallManager.shared
        self.mediaPipeline = mediaPipeline ?? DefaultCallMediaPipeline.shared
        self.signalingHandler = signalingHandler
            ?? DIContainer.shared.resolveOptional(CallSignalingHandlerProtocol.self)
            ?? MockCallSignalingHandler.shared
        subscribeToCallKitEvents()
        subscribeToSignaling()
    }

    /// For DI / testing
    static func create(
        callManager: CallManager? = nil,
        signalingHandler: CallSignalingHandlerProtocol? = nil,
        mediaPipeline: CallMediaPipelineProtocol? = nil
    ) -> CallService {
        CallService(callManager: callManager, signalingHandler: signalingHandler, mediaPipeline: mediaPipeline)
    }

    func configure(signalingHandler: CallSignalingHandlerProtocol) {
        self.signalingHandler = signalingHandler
        cancellables.removeAll()
        subscribeToCallKitEvents()
        subscribeToSignaling()
    }

    func configure(messageHandler: WebSocketMessageHandler) {
        let wsHandler = WebSocketCallSignalingHandler(messageHandler: messageHandler)
        configure(signalingHandler: wsHandler)
    }

    // MARK: - Outgoing Call

    func initiateCall(to userId: String, name: String, avatarURL: URL? = nil, hasVideo: Bool) async throws {
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
            remoteAvatarURL: avatarURL,
            hasVideo: hasVideo,
            isOutgoing: true,
            startedAt: Date()
        )
        currentCall = call
        currentCallState = .initiating

        do {
            // 1. Report to CallKit
            try await callManager.startOutgoingCall(
                uuid: uuid,
                callId: callId,
                remoteUserId: userId,
                remoteName: name,
                hasVideo: hasVideo
            )

            // 2. Start Centralized Media Pipeline
            try? await mediaPipeline.startAudio()
            if hasVideo {
                try? await mediaPipeline.startVideo(isFront: true)
            }

            // 3. Send callInitiate signal safely
            let currentUserId = SessionStore.shared.currentUserId
            do {
                try await signalingHandler.send(
                    signal: .callInitiate(
                        callId: callId,
                        fromUserId: currentUserId,
                        toUserId: userId,
                        callType: hasVideo ? .video : .audio
                    )
                )
            } catch {
                logger.notice("Signaling send callInitiate warning: \(error.localizedDescription)")
                if !(signalingHandler is MockCallSignalingHandler) && AppConfig.shared.callBackendMode != .mock {
                    throw error
                }
            }

            currentCallState = .ringing
            callManager.reportOutgoingCallStartedConnecting(uuid: uuid)
            mediaPipeline.startRingbackTone()
            startRingTimeout()
        } catch {
            logger.error("Failed to initiate call: \(error.localizedDescription)")
            cancelRingTimeout()
            mediaPipeline.stopRingbackTone()
            mediaPipeline.stopVideo()
            mediaPipeline.stopAudio()
            currentCall = nil
            currentCallState = .idle
            try? await callManager.endCall(uuid: uuid)
            throw error
        }
    }

    // MARK: - Accept Incoming Call

    func acceptIncomingCall() async throws {
        guard currentCallState == .incomingRinging,
              let call = currentCall else {
            throw CallServiceError.noIncomingCall
        }

        cancelRingTimeout()
        mediaPipeline.stopIncomingRingtone()
        currentCallState = .connecting

        // Centralized Media Start
        try? await mediaPipeline.startAudio()
        if call.hasVideo {
            try? await mediaPipeline.startVideo(isFront: true)
        }

        let currentUserId = SessionStore.shared.currentUserId
        do {
            try await signalingHandler.send(
                signal: .callAnswer(
                    callId: call.id,
                    fromUserId: currentUserId,
                    toUserId: call.remoteUserId,
                    sdp: "placeholder_sdp_answer"
                )
            )
        } catch {
            logger.notice("Failed to send answer signal: \(error.localizedDescription)")
        }

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
        mediaPipeline.stopIncomingRingtone()

        let currentUserId = SessionStore.shared.currentUserId
        do {
            try await signalingHandler.send(
                signal: .callReject(
                    callId: call.id,
                    fromUserId: currentUserId,
                    toUserId: call.remoteUserId
                )
            )
        } catch {
            logger.notice("Failed to send reject signal: \(error.localizedDescription)")
        }

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
        mediaPipeline.stopRingbackTone()
        mediaPipeline.stopIncomingRingtone()

        let callId = call.id
        let uuid = call.uuid
        let remoteUserId = call.remoteUserId
        let currentUserId = SessionStore.shared.currentUserId

        do {
            try await signalingHandler.send(
                signal: .callHangup(
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

    // MARK: - Media Controls

    func setMuted(_ isMuted: Bool) {
        guard var call = currentCall else { return }
        call.isMuted = isMuted
        currentCall = call
        mediaPipeline.setMuted(isMuted)
        Task {
            try? await callManager.setMuted(uuid: call.uuid, muted: isMuted)
        }
    }

    func setSpeaker(_ isSpeaker: Bool) {
        guard var call = currentCall else { return }
        call.isSpeakerOn = isSpeaker
        currentCall = call
        mediaPipeline.setSpeaker(isSpeaker)
    }

    func flipCamera(isFront: Bool) async {
        await mediaPipeline.switchCamera(isFront: isFront)
    }

    func toggleCamera(isOff: Bool) async {
        guard var call = currentCall else { return }
        if isOff {
            mediaPipeline.stopVideo()
            call.hasVideo = false
        } else {
            try? await mediaPipeline.startVideo(isFront: true)
            call.hasVideo = true
        }
        currentCall = call
    }

    func toggleMute() async throws {
        guard let call = currentCall else {
            throw CallServiceError.noActiveCall
        }
        setMuted(!call.isMuted)
    }

    func toggleSpeaker() async throws {
        guard let call = currentCall else {
            throw CallServiceError.noActiveCall
        }
        setSpeaker(!call.isSpeakerOn)
    }

    func upgradeToVideo() async throws {
        guard var call = currentCall, currentCallState == .connected else {
            throw CallServiceError.noActiveCall
        }
        guard !call.hasVideo else { return }

        call.hasVideo = true
        currentCall = call
        try? await mediaPipeline.startVideo(isFront: true)

        let currentUserId = SessionStore.shared.currentUserId
        try? await signalingHandler.send(
            signal: .callOffer(
                callId: call.id,
                fromUserId: currentUserId,
                toUserId: call.remoteUserId,
                sdp: "upgrade_to_video_renegotiation"
            )
        )
        logger.info("Call successfully upgraded to video for call \(call.id)")
    }

    // MARK: - Handle Incoming Call

    /// Called when a call signal arrives (via Signaling transport or VoIP push).
    func handleIncomingCall(signal: CallSignal, callerName: String, avatarURL: URL? = nil, uuid: UUID? = nil) async {
        guard currentCallState == .idle || !currentCallState.isActive else {
            // Already in an active call — send busy
            let currentUserId = SessionStore.shared.currentUserId
            try? await signalingHandler.send(
                signal: .callBusy(callId: signal.callId, fromUserId: currentUserId, toUserId: signal.fromUserId)
            )
            return
        }

        let callUUID = uuid ?? UUID()
        let call = ActiveCall(
            id: signal.callId,
            uuid: callUUID,
            remoteUserId: signal.fromUserId,
            remoteName: callerName,
            remoteAvatarURL: avatarURL,
            hasVideo: signal.callType == .video,
            isOutgoing: false,
            startedAt: Date()
        )
        currentCall = call
        currentCallState = .incomingRinging

        // Centralized incoming ringtone chime
        mediaPipeline.startIncomingRingtone()

        // If uuid was passed in (e.g. from VoIP push), CallKit was already reported by VoIPPushService.
        // Only report to CallKit if uuid == nil (e.g. incoming from in-app signaling).
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
        try? await signalingHandler.send(
            signal: .callRinging(callId: signal.callId, fromUserId: currentUserId, toUserId: signal.fromUserId)
        )

        // Notice: Full-screen presentation is handled by router observing currentCallState == .incomingRinging.
        startRingTimeout()
    }

    // MARK: - Simulate Incoming Call (Testing / Debug)

    func simulateIncomingCall(fromUserId: String, name: String, hasVideo: Bool) async {
        if let mock = signalingHandler as? MockCallSignalingHandler {
            mock.simulateIncomingCall(fromUserId: fromUserId, name: name, hasVideo: hasVideo)
        } else if let firebase = signalingHandler as? FirebaseCallSignalingHandler {
            firebase.simulateIncomingCall(fromUserId: fromUserId, name: name, hasVideo: hasVideo)
        } else {
            let signal = CallSignal.callIncoming(
                callId: UUID().uuidString,
                fromUserId: fromUserId,
                toUserId: SessionStore.shared.currentUserId,
                callType: hasVideo ? .video : .audio,
                callerName: name,
                avatarURL: nil
            )
            await handleIncomingCall(signal: signal, callerName: name)
        }
    }

    // MARK: - Private: End Call Cleanup

    private func endCall(reason: CallEndReason) {
        cancelRingTimeout()

        // Stop media and tones immediately
        mediaPipeline.stopRingbackTone()
        mediaPipeline.stopIncomingRingtone()
        mediaPipeline.stopVideo()
        mediaPipeline.stopAudio()

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
            setMuted(muted)

        case .audioSessionActivated:
            // Media pipeline audio active
            break

        case .audioSessionDeactivated:
            // Media pipeline audio deactivated
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

    // MARK: - Private: Subscribe to Signaling

    private func subscribeToSignaling() {
        signalingHandler.incomingSignalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] signal in
                guard let self else { return }
                Task { @MainActor in
                    self.handleIncomingSignal(signal)
                }
            }
            .store(in: &cancellables)
    }

    private func handleIncomingSignal(_ signal: CallSignal) {
        switch signal {
        case .callIncoming(_, let fromUserId, _, _, let callerName, let avatarURL):
            Task {
                await self.handleIncomingCall(
                    signal: signal,
                    callerName: callerName ?? fromUserId,
                    avatarURL: avatarURL
                )
            }

        case .callInitiate(_, let fromUserId, _, _):
            Task {
                await self.handleIncomingCall(
                    signal: signal,
                    callerName: fromUserId
                )
            }

        case .callOffer(let callId, _, _, _):
            logger.info("Received call offer for \(callId)")

        case .callAnswer(let callId, _, _, _):
            logger.info("Received call answer for \(callId)")
            cancelRingTimeout()
            mediaPipeline.stopRingbackTone()
            if currentCallState == .ringing || currentCallState == .connecting {
                currentCallState = .connected
                currentCall?.connectedAt = Date()
                if let uuid = currentCall?.uuid {
                    callManager.reportCallConnected(uuid: uuid, isOutgoing: true)
                }
            }

        case .callIceCandidate(let callId, _, _, _, _, _):
            logger.info("Received ICE candidate for \(callId)")

        case .callHangup(let callId, _, _):
            if currentCall?.id == callId {
                mediaPipeline.stopRingbackTone()
                mediaPipeline.stopIncomingRingtone()
                if let uuid = currentCall?.uuid {
                    callManager.reportCallEnded(uuid: uuid, reason: .remoteEnded)
                }
                endCall(reason: .remoteHangup)
            }

        case .callReject(let callId, _, _):
            if currentCall?.id == callId {
                mediaPipeline.stopRingbackTone()
                mediaPipeline.stopIncomingRingtone()
                if let uuid = currentCall?.uuid {
                    callManager.reportCallEnded(uuid: uuid, reason: .declinedElsewhere)
                }
                endCall(reason: .rejected)
            }

        case .callBusy(let callId, _, _):
            if currentCall?.id == callId {
                mediaPipeline.stopRingbackTone()
                mediaPipeline.stopIncomingRingtone()
                if let uuid = currentCall?.uuid {
                    callManager.reportCallEnded(uuid: uuid, reason: .unanswered)
                }
                endCall(reason: .busy)
            }

        case .callRinging(let callId, _, _):
            if currentCall?.id == callId, (currentCallState == .initiating || currentCallState == .ringing) {
                currentCallState = .ringing
                mediaPipeline.startRingbackTone()
            }
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
