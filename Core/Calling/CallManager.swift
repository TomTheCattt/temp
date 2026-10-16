//
//  CallManager.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
internal import CallKit
import AVFoundation
import Combine
import UIKit

// MARK: - CallManager

/// Manages CXProvider and CXCallController to integrate with iOS CallKit.
/// Handles reporting incoming calls, starting outgoing calls, and responding to
/// system call actions (answer, end, hold, mute).
final class CallManager: NSObject, @unchecked Sendable {

    static let shared = CallManager()

    // MARK: - Publishers

    private let callEventSubject = PassthroughSubject<CallKitEvent, Never>()

    /// Stream of CallKit events for CallService to observe.
    var callEvents: AnyPublisher<CallKitEvent, Never> {
        callEventSubject.eraseToAnyPublisher()
    }

    // MARK: - Properties

    private let provider: CXProvider
    private let callController = CXCallController()
    private let logger = AppLogger.general

    /// Currently active call UUIDs tracked by CallKit.
    private var activeCalls: [UUID: CallInfo] = [:]
    private let queue = DispatchQueue(label: "com.instagram.callmanager")
    private let queueKey = DispatchSpecificKey<Void>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    private override init() {
        let configuration = CXProviderConfiguration()
        configuration.supportsVideo = true
        configuration.maximumCallGroups = 1
        configuration.supportedHandleTypes = [.generic]
        configuration.includesCallsInRecents = true

        // Icon shown in the native call UI
        if let iconImage = UIImage(named: "AppIcon") {
            configuration.iconTemplateImageData = iconImage.pngData()
        }

        provider = CXProvider(configuration: configuration)

        super.init()

        queue.setSpecific(key: queueKey, value: ())
        provider.setDelegate(self, queue: queue)
        setupAudioSessionObservers()
    }

    private func syncOnQueue<T>(_ block: () -> T) -> T {
        if DispatchQueue.getSpecific(key: queueKey) != nil {
            return block()
        } else {
            return queue.sync { block() }
        }
    }

    // MARK: - Report Incoming Call

    /// Report an incoming call to the system (shows native call UI).
    /// Called when receiving a VoIP push or WebSocket call signal.
    func reportIncomingCall(
        uuid: UUID,
        callId: String,
        callerName: String,
        callerUserId: String,
        hasVideo: Bool
    ) async throws {
        let update = CXCallUpdate()
        update.localizedCallerName = callerName
        update.remoteHandle = CXHandle(type: .generic, value: callerUserId)
        update.hasVideo = hasVideo
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.supportsHolding = false
        update.supportsDTMF = false

        // Track the call
        let callInfo = CallInfo(
            uuid: uuid,
            callId: callId,
            remoteUserId: callerUserId,
            callerName: callerName,
            isOutgoing: false,
            hasVideo: hasVideo
        )
        syncOnQueue { activeCalls[uuid] = callInfo }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            provider.reportNewIncomingCall(with: uuid, update: update) { [weak self] error in
                if let error {
                    self?.syncOnQueue { _ = self?.activeCalls.removeValue(forKey: uuid) }
                    self?.logger.error("Failed to report incoming call: \(error.localizedDescription)")
                    #if targetEnvironment(simulator)
                    // Simulator fallback: continue even if CallKit native UI has sandbox limitations
                    self?.logger.notice("Simulator fallback for incoming call")
                    continuation.resume()
                    #else
                    continuation.resume(throwing: error)
                    #endif
                } else {
                    self?.logger.info("Reported incoming call from \(callerName)")
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Start Outgoing Call

    /// Request the system to start an outgoing call.
    func startOutgoingCall(
        uuid: UUID,
        callId: String,
        remoteUserId: String,
        remoteName: String,
        hasVideo: Bool
    ) async throws {
        let handle = CXHandle(type: .generic, value: remoteUserId)
        let startCallAction = CXStartCallAction(call: uuid, handle: handle)
        startCallAction.isVideo = hasVideo
        startCallAction.contactIdentifier = remoteName

        let callInfo = CallInfo(
            uuid: uuid,
            callId: callId,
            remoteUserId: remoteUserId,
            callerName: remoteName,
            isOutgoing: true,
            hasVideo: hasVideo
        )
        syncOnQueue { activeCalls[uuid] = callInfo }

        let transaction = CXTransaction(action: startCallAction)
        do {
            try await callController.request(transaction)
            logger.info("Started outgoing call to \(remoteName)")
        } catch {
            logger.notice("CallKit startOutgoingCall warning: \(error.localizedDescription)")
            #if targetEnvironment(simulator)
            // On simulator, CallKit provider may fail; bypass error so in-app call view works seamlessly
            logger.info("Simulator fallback: proceeding with in-app call flow")
            #else
            throw error
            #endif
        }
    }

    // MARK: - End Call

    /// Request the system to end a call.
    func endCall(uuid: UUID) async throws {
        let isTracked = syncOnQueue { activeCalls[uuid] != nil }
        guard isTracked else {
            logger.info("Call \(uuid) is not active in CallManager; skipping redundant CXEndCallAction")
            return
        }

        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)
        do {
            try await callController.request(transaction)
        } catch {
            logger.notice("CallKit endCall request warning: \(error.localizedDescription)")
        }
        syncOnQueue { _ = activeCalls.removeValue(forKey: uuid) }
        deactivateAudioSession()
    }

    // MARK: - Report Call Connected

    /// Notify the system that the outgoing call has connected (ringing → connected).
    func reportOutgoingCallConnected(uuid: UUID) {
        provider.reportOutgoingCall(with: uuid, connectedAt: Date())
    }

    /// Notify the system that the incoming call has connected (answering → connected).
    func reportIncomingCallConnected(uuid: UUID) {
        logger.info("Incoming call \(uuid) connected")
    }

    /// Reports call connected based on direction.
    func reportCallConnected(uuid: UUID, isOutgoing: Bool) {
        if isOutgoing {
            reportOutgoingCallConnected(uuid: uuid)
        } else {
            reportIncomingCallConnected(uuid: uuid)
        }
    }

    /// Notify the system that the outgoing call started connecting.
    func reportOutgoingCallStartedConnecting(uuid: UUID) {
        provider.reportOutgoingCall(with: uuid, startedConnectingAt: Date())
    }

    // MARK: - Report Call Ended

    /// Report that a call has ended (e.g. remote hangup).
    func reportCallEnded(uuid: UUID, reason: CXCallEndedReason) {
        syncOnQueue { _ = activeCalls.removeValue(forKey: uuid) }
        provider.reportCall(with: uuid, endedAt: Date(), reason: reason)
        deactivateAudioSession()
    }

    // MARK: - Mute

    func setMuted(uuid: UUID, muted: Bool) async throws {
        let muteAction = CXSetMutedCallAction(call: uuid, muted: muted)
        let transaction = CXTransaction(action: muteAction)
        try await callController.request(transaction)
    }

    // MARK: - Helpers

    func callInfo(for uuid: UUID) -> CallInfo? {
        syncOnQueue { activeCalls[uuid] }
    }

    func callUUID(for callId: String) -> UUID? {
        syncOnQueue {
            activeCalls.first(where: { $0.value.callId == callId })?.key
        }
    }

    var hasActiveCall: Bool {
        syncOnQueue { !activeCalls.isEmpty }
    }
}

// MARK: - CXProviderDelegate

extension CallManager: CXProviderDelegate {

    func providerDidReset(_ provider: CXProvider) {
        logger.info("CXProvider did reset")
        syncOnQueue { activeCalls.removeAll() }
        deactivateAudioSession()
        callEventSubject.send(.providerDidReset)
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        logger.info("CXProvider: start call action")
        configureAudioSession()
        callEventSubject.send(.startCall(uuid: action.callUUID))
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        logger.info("CXProvider: answer call action")
        configureAudioSession()
        callEventSubject.send(.answerCall(uuid: action.callUUID))
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        logger.info("CXProvider: end call action")
        let uuid = action.callUUID
        syncOnQueue { _ = activeCalls.removeValue(forKey: uuid) }
        callEventSubject.send(.endCall(uuid: uuid))
        deactivateAudioSession()
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        callEventSubject.send(.setMuted(uuid: action.callUUID, muted: action.isMuted))
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        callEventSubject.send(.setHeld(uuid: action.callUUID, held: action.isOnHold))
        action.fulfill()
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        logger.info("Audio session activated by CallKit delegate")
        do {
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            logger.debug("Audio session setActive in didActivate non-fatal: \(error.localizedDescription)")
        }
        callEventSubject.send(.audioSessionActivated)
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        logger.info("Audio session deactivated")
        callEventSubject.send(.audioSessionDeactivated)
    }

    // MARK: - Audio Configuration

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetoothHFP, .allowBluetoothA2DP, .allowAirPlay]
            )
            #if targetEnvironment(simulator)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            #endif
        } catch {
            logger.error("Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    func deactivateAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(false, options: .notifyOthersOnDeactivation)
            logger.info("Audio session cleanly deactivated")
        } catch {
            logger.error("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }

    private func setupAudioSessionObservers() {
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                self?.handleAudioInterruption(notification)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .sink { [weak self] notification in
                self?.handleAudioRouteChange(notification)
            }
            .store(in: &cancellables)
    }

    private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            logger.info("Audio session interruption began (e.g. cellular call)")
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    logger.info("Audio session interruption ended: resuming audio")
                    configureAudioSession()
                    do {
                        try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                    } catch {
                        logger.error("Failed to reactivate audio session: \(error.localizedDescription)")
                    }
                    callEventSubject.send(.audioSessionActivated)
                }
            }
        @unknown default:
            break
        }
    }

    private func handleAudioRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        logger.info("Audio route changed: reason = \(reason.rawValue)")
    }
}

// MARK: - CallKitEvent

/// Events emitted by CallManager for CallService to handle.
enum CallKitEvent: Sendable {
    case startCall(uuid: UUID)
    case answerCall(uuid: UUID)
    case endCall(uuid: UUID)
    case setMuted(uuid: UUID, muted: Bool)
    case setHeld(uuid: UUID, held: Bool)
    case audioSessionActivated
    case audioSessionDeactivated
    case providerDidReset
}

// MARK: - CallInfo

/// Metadata for an active call tracked by CallManager.
struct CallInfo: Sendable {
    let uuid: UUID
    let callId: String
    let remoteUserId: String
    let callerName: String
    let isOutgoing: Bool
    let hasVideo: Bool
    let startedAt: Date = Date()
}
