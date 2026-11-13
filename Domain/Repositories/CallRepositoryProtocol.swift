//
//  CallRepositoryProtocol.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Combine

// MARK: - CallRepositoryProtocol

/// Protocol defining the contract for call data operations.
protocol CallRepositoryProtocol: Sendable {

    // MARK: - Call History & Details

    /// Fetches paginated call history for the current user.
    func getCallHistory(page: Int, perPage: Int, type: CallType?, status: CallStatus?) -> AnyPublisher<PaginatedCalls, Error>

    /// Fetches call history items for the call history view (simplified).
    func fetchCallHistory() async throws -> [CallHistoryItem]

    /// Fetches detailed call information.
    func getCallDetail(callId: String) -> AnyPublisher<Call, Error>

    /// Deletes a call history item.
    func deleteCallHistory(id: String) async throws

    /// Clears all call history.
    func clearCallHistory() async throws

    // MARK: - Call Management

    /// Creates a new call record.
    func createCall(
        participantIds: [String],
        callType: CallType,
        startedAt: Date,
        endedAt: Date?,
        conversationId: String?,
        maxParticipants: Int?,
        isRecording: Bool?,
        metadata: [String: String]?
    ) -> AnyPublisher<Call, Error>

    /// Joins an existing call.
    func joinCall(callId: String, deviceType: String?, appVersion: String?) -> AnyPublisher<Call, Error>

    /// Leaves a call.
    func leaveCall(callId: String, reason: String?) -> AnyPublisher<Void, Error>

    /// Ends a call.
    func endCall(callId: String, reason: String?) -> AnyPublisher<Void, Error>

    /// Invites participants to a call.
    func inviteParticipants(callId: String, participantIds: [String]) -> AnyPublisher<Void, Error>

    /// Kicks a participant from a call.
    func kickParticipant(callId: String, targetUserId: String, reason: String?) -> AnyPublisher<Void, Error>

    /// Updates a participant's media state.
    func updateParticipant(callId: String, targetUserId: String, isMuted: Bool?, isVideoOff: Bool?, isScreenShare: Bool?) -> AnyPublisher<Void, Error>

    /// Transfers host role to another participant.
    func transferHost(callId: String, newHostId: String) -> AnyPublisher<Void, Error>

    // MARK: - Call Recording

    /// Gets call recording information.
    func getCallRecording(callId: String) -> AnyPublisher<CallRecording, Error>

    // MARK: - Quality Metrics

    /// Records quality metrics for a call participant.
    func recordQualityMetrics(
        callId: String,
        participantId: String,
        bitrate: Double,
        packetLoss: Double,
        latency: Double,
        jitter: Double,
        fps: Double?,
        resolution: (width: Int, height: Int)?
    ) -> AnyPublisher<Void, Error>

    /// Gets quality metrics for a call participant.
    func getQualityMetrics(callId: String, participantId: String) -> AnyPublisher<CallQualityMetrics, Error>

    // MARK: - Update Call Record

    /// Updates a call record (status, endedAt, duration).
    func updateCall(
        callId: String,
        endedAt: Date?,
        duration: Int?,
        status: CallStatus
    ) -> AnyPublisher<Call, Error>

    // MARK: - CallKit Endpoints

    /// Registers a device for CallKit push notifications.
    func registerCallKitDevice(
        deviceToken: String,
        voipToken: String?,
        platform: String,
        deviceId: String?,
        appVersion: String?,
        osVersion: String?,
        sandbox: Bool,
        topics: [String]?
    ) -> AnyPublisher<CallKitRegistration, Error>

    /// Updates VoIP token for existing device token.
    func updateVoipToken(deviceToken: String, voipToken: String) -> AnyPublisher<CallKitRegistration, Error>

    /// Unregisters a CallKit device.
    func unregisterCallKitDevice(deviceToken: String) -> AnyPublisher<Void, Error>

    /// Lists user's CallKit devices.
    func listCallKitDevices() -> AnyPublisher<[CallKitDevice], Error>

    /// Gets ICE servers for WebRTC.
    func getIceServers() -> AnyPublisher<[IceServer], Error>

    /// Reports CallKit call result.
    func reportCallKitResult(
        callId: String,
        answered: Bool,
        duration: Int?
    ) -> AnyPublisher<CallKitReportResponse, Error>

    // MARK: - CallKit Test Endpoints (Dev Only)

    /// Sends test incoming call VoIP push.
    func testIncomingCall(
        callId: String?,
        roomId: String?,
        callerName: String?,
        callerUsername: String?,
        hasVideo: Bool?,
        isGroupCall: Bool?,
        iceServers: [[String: String]]?
    ) -> AnyPublisher<TestCallResult, Error>

    /// Sends test call event.
    func testCallEvent(
        callId: String,
        roomId: String?,
        calleeId: String,
        callerId: String,
        eventType: String,
        metadata: [String: String]?
    ) -> AnyPublisher<TestCallEventResult, Error>

    // MARK: - CallKit Internal/Service Endpoints

    /// Notifies that a call was initiated (internal).
    func callInitiated(
        callId: String,
        roomId: String,
        callerId: String,
        calleeIds: [String],
        callerName: String,
        callerUsername: String,
        callerAvatarUrl: String?,
        hasVideo: Bool,
        isGroupCall: Bool
    ) -> AnyPublisher<CallInitiatedResult, Error>

    /// Notifies call event (internal).
    func callEvent(
        callId: String,
        roomId: String?,
        calleeId: String,
        callerId: String,
        eventType: String,
        metadata: [String: String]?
    ) -> AnyPublisher<CallEventResult, Error>

    // MARK: - Stats & Cleanup

    /// Gets VoIP push service stats.
    func getCallKitStats() -> AnyPublisher<CallKitStats, Error>

    /// Cleans up expired device tokens (internal cron).
    func cleanupCallKitDevices() -> AnyPublisher<CleanupResult, Error>
}

// MARK: - Call History Item (for UI)

/// Simplified call item for history view.
struct CallHistoryItem: Identifiable, Sendable {
    let id: String
    let otherUserId: String
    let otherUserName: String
    let otherUserUsername: String
    let otherUserAvatarURL: URL?
    let type: CallType
    let direction: CallDirection
    let startedAt: Date
    let duration: TimeInterval?
    let isMissed: Bool
}

/// Call direction for history view.
enum CallDirection: Sendable {
    case incoming
    case outgoing

    var title: String {
        switch self {
        case .incoming: return "Incoming"
        case .outgoing: return "Outgoing"
        }
    }

    var icon: String {
        switch self {
        case .incoming: return "arrow.down.left"
        case .outgoing: return "arrow.up.right"
        }
    }
}