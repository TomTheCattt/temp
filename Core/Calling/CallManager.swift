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

        provider.setDelegate(self, queue: queue)
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
        queue.sync { activeCalls[uuid] = callInfo }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            provider.reportNewIncomingCall(with: uuid, update: update) { [weak self] error in
                if let error {
                    self?.queue.sync { _ = self?.activeCalls.removeValue(forKey: uuid) }
                    self?.logger.error("Failed to report incoming call: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
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
        queue.sync { activeCalls[uuid] = callInfo }

        let transaction = CXTransaction(action: startCallAction)
        try await callController.request(transaction)

        logger.info("Started outgoing call to \(remoteName)")
    }

    // MARK: - End Call

    /// Request the system to end a call.
    func endCall(uuid: UUID) async throws {
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)
        try await callController.request(transaction)
    }

    // MARK: - Report Call Connected

    /// Notify the system that the outgoing call has connected (ringing → connected).
    func reportOutgoingCallConnected(uuid: UUID) {
        provider.reportOutgoingCall(with: uuid, connectedAt: Date())
    }

    /// Notify the system that the outgoing call started connecting.
    func reportOutgoingCallStartedConnecting(uuid: UUID) {
        provider.reportOutgoingCall(with: uuid, startedConnectingAt: Date())
    }

    // MARK: - Report Call Ended

    /// Report that a call has ended (e.g. remote hangup).
    func reportCallEnded(uuid: UUID, reason: CXCallEndedReason) {
        provider.reportCall(with: uuid, endedAt: Date(), reason: reason)
        queue.sync { _ = activeCalls.removeValue(forKey: uuid) }
    }

    // MARK: - Mute

    func setMuted(uuid: UUID, muted: Bool) async throws {
        let muteAction = CXSetMutedCallAction(call: uuid, muted: muted)
        let transaction = CXTransaction(action: muteAction)
        try await callController.request(transaction)
    }

    // MARK: - Helpers

    func callInfo(for uuid: UUID) -> CallInfo? {
        queue.sync { activeCalls[uuid] }
    }

    func callUUID(for callId: String) -> UUID? {
        queue.sync {
            activeCalls.first(where: { $0.value.callId == callId })?.key
        }
    }

    var hasActiveCall: Bool {
        queue.sync { !activeCalls.isEmpty }
    }
}

// MARK: - CXProviderDelegate

extension CallManager: CXProviderDelegate {

    func providerDidReset(_ provider: CXProvider) {
        logger.info("CXProvider did reset")
        queue.sync { activeCalls.removeAll() }
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
        callEventSubject.send(.endCall(uuid: uuid))
        queue.sync { _ = activeCalls.removeValue(forKey: uuid) }
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
        logger.info("Audio session activated")
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
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetoothA2DP])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            logger.error("Failed to configure audio session: \(error.localizedDescription)")
        }
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
