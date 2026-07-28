//
//  VoIPPushService.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import PushKit
import Combine
internal import CallKit

// MARK: - VoIPPushServiceProtocol

protocol VoIPPushServiceProtocol: AnyObject {
    var voipToken: String? { get }
    func registerForVoIPPushes()
}

// MARK: - VoIPPushService

/// Handles PushKit VoIP pushes for incoming calls.
/// VoIP pushes wake the app instantly and MUST report a call to CallKit
/// within the same callback — otherwise iOS will terminate the app.
final class VoIPPushService: NSObject, VoIPPushServiceProtocol, @unchecked Sendable {

    static let shared = VoIPPushService()

    // MARK: - Properties

    private var voipRegistry: PKPushRegistry?
    private(set) var voipToken: String?
    private let logger = AppLogger.general

    private override init() {
        super.init()
    }

    // MARK: - Registration

    /// Register for VoIP pushes. Call this at app launch.
    func registerForVoIPPushes() {
        let registry = PKPushRegistry(queue: DispatchQueue.main)
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
        voipRegistry = registry
        logger.info("VoIP push registration requested")
    }
}

// MARK: - PKPushRegistryDelegate

extension VoIPPushService: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP else { return }

        let token = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        voipToken = token
        logger.info("VoIP push token: \(token.prefix(16))...")

        // TODO: Send VoIP token to backend
        // NetworkService.registerVoIPToken(token)
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        guard type == .voIP else { return }
        voipToken = nil
        logger.info("VoIP push token invalidated")
    }

    /// CRITICAL: This method MUST report a call to CallKit before returning.
    /// If it fails to do so, iOS will terminate the app.
    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        guard type == .voIP else {
            completion()
            return
        }

        logger.info("VoIP push received")

        let payloadDict = payload.dictionaryPayload

        // Extract call information from push payload
        let callId = payloadDict["call_id"] as? String ?? UUID().uuidString
        let callerName = payloadDict["caller_name"] as? String ?? "Unknown"
        let callerUserId = payloadDict["caller_user_id"] as? String ?? ""
        let hasVideo = (payloadDict["call_type"] as? String) == "video"

        let uuid = UUID()

        // MUST report to CallKit synchronously within this callback
        Task { @MainActor in
            do {
                try await CallManager.shared.reportIncomingCall(
                    uuid: uuid,
                    callId: callId,
                    callerName: callerName,
                    callerUserId: callerUserId,
                    hasVideo: hasVideo
                )

                // Notify CallService about the incoming call
                let signal = CallSignal(
                    callId: callId,
                    fromUserId: callerUserId,
                    toUserId: "", // current user
                    callType: hasVideo ? .video : .audio,
                    sdp: payloadDict["sdp"] as? String,
                    iceCandidate: nil,
                    iceSdpMid: nil,
                    iceSdpMLineIndex: nil,
                    timestamp: Date()
                )

                await CallService.shared.handleIncomingCall(
                    signal: signal,
                    callerName: callerName
                )
            } catch {
                // If we fail to report the call, we MUST still complete.
                // CallKit will show a missed call.
                logger.error("Failed to handle VoIP push: \(error.localizedDescription)")

                // Report and immediately end to satisfy iOS requirement
                CallManager.shared.reportCallEnded(uuid: uuid, reason: .failed)
            }

            completion()
        }
    }
}
