//
//  CallEndpoint.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Alamofire

// MARK: - CallEndpoint (REST endpoints for call management)

enum CallEndpoint: APIEndpoint {
    // Get call history
    case history(page: Int, perPage: Int, type: CallType?, status: CallStatus?)

    // Get call details
    case detail(callId: String)

    // Create call record
    case create(
        participantIds: [String],
        callType: CallType,
        startedAt: Date,
        endedAt: Date?,
        conversationId: String?,
        maxParticipants: Int?,
        isRecording: Bool?,
        metadata: [String: Any]?
    )

    // Join call
    case join(callId: String, deviceType: String?, appVersion: String?)

    // Leave call
    case leave(callId: String, reason: String?)

    // End call
    case end(callId: String, reason: String?)

    // Invite participants
    case invite(callId: String, participantIds: [String])

    // Kick participant
    case kick(callId: String, targetUserId: String, reason: String?)

    // Update participant media state
    case updateParticipant(callId: String, targetUserId: String, isMuted: Bool?, isVideoOff: Bool?, isScreenShare: Bool?)

    // Transfer host
    case transferHost(callId: String, newHostId: String)

    // Get call recording
    case recording(callId: String)

    // Record quality metrics
    case qualityMetrics(callId: String, participantId: String, bitrate: Double, packetLoss: Double, latency: Double, jitter: Double, fps: Double?, resolution: (width: Int, height: Int)?)

    // Get quality metrics
    case getQualityMetrics(callId: String)

    // Update call record
    case update(
        callId: String,
        endedAt: Date?,
        duration: Int?,
        status: CallStatus
    )

    var path: String {
        switch self {
        case .history:
            return "/v1/calls/history"
        case .detail(let callId):
            return "/v1/calls/\(callId)"
        case .create:
            return "/v1/calls"
        case .join(let callId, _, _):
            return "/v1/calls/\(callId)/join"
        case .leave(let callId, _):
            return "/v1/calls/\(callId)/leave"
        case .end(let callId, _):
            return "/v1/calls/\(callId)/end"
        case .invite(let callId, _):
            return "/v1/calls/\(callId)/invite"
        case .kick(let callId, _, _):
            return "/v1/calls/\(callId)/kick"
        case .updateParticipant(let callId, let targetUserId, _, _, _):
            return "/v1/calls/\(callId)/participants/\(targetUserId)"
        case .transferHost(let callId, _):
            return "/v1/calls/\(callId)/host/transfer"
        case .recording(let callId):
            return "/v1/calls/\(callId)/recording"
        case .qualityMetrics(let callId, _, _, _, _, _, _, _):
            return "/v1/calls/\(callId)/quality"
        case .getQualityMetrics(let callId):
            return "/v1/calls/\(callId)/quality"
        case .update(let callId, _, _, _):
            return "/v1/calls/\(callId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .history, .detail, .recording, .getQualityMetrics:
            return .get
        case .create, .join, .leave, .end, .invite, .kick, .updateParticipant, .transferHost, .qualityMetrics:
            return .post
        case .update:
            return .put
        }
    }

    var parameters: Parameters? {
        let formatter = ISO8601DateFormatter()
        switch self {
        case .history(let page, let perPage, let type, let status):
            var params: Parameters = ["page": page, "perPage": perPage]
            if let type { params["type"] = type.rawValue }
            if let status { params["status"] = status.rawValue }
            return params

        case .detail:
            return nil

        case .create(let participantIds, let callType, let startedAt, let endedAt, let conversationId, let maxParticipants, let isRecording, let metadata):
            var params: Parameters = [
                "participantIds": participantIds,
                "type": callType.rawValue,
                "startedAt": formatter.string(from: startedAt)
            ]
            if let endedAt { params["endedAt"] = formatter.string(from: endedAt) }
            if let conversationId { params["conversationId"] = conversationId }
            if let maxParticipants { params["maxParticipants"] = maxParticipants }
            if let isRecording { params["isRecording"] = isRecording }
            if let metadata { params["metadata"] = metadata }
            return params

        case .join(_, let deviceType, let appVersion):
            var params: Parameters = [:]
            if let deviceType { params["deviceType"] = deviceType }
            if let appVersion { params["appVersion"] = appVersion }
            return params

        case .leave(_, let reason):
            if let reason { return ["reason": reason] }
            return nil

        case .end(_, let reason):
            if let reason { return ["reason": reason] }
            return nil

        case .invite(_, let participantIds):
            return ["participantIds": participantIds]

        case .kick(_, let targetUserId, let reason):
            var params: Parameters = ["targetUserId": targetUserId]
            if let reason { params["reason"] = reason }
            return params

        case .updateParticipant(_, _, let isMuted, let isVideoOff, let isScreenShare):
            var params: Parameters = [:]
            if let isMuted { params["isMuted"] = isMuted }
            if let isVideoOff { params["isVideoOff"] = isVideoOff }
            if let isScreenShare { params["isScreenShare"] = isScreenShare }
            return params

        case .transferHost(_, let newHostId):
            return ["newHostId": newHostId]

        case .recording:
            return nil

        case .qualityMetrics(_, let participantId, let bitrate, let packetLoss, let latency, let jitter, let fps, let resolution):
            var params: Parameters = [
                "participantId": participantId,
                "bitrate": bitrate,
                "packetLoss": packetLoss,
                "latency": latency,
                "jitter": jitter
            ]
            if let fps { params["fps"] = fps }
            if let resolution { params["resolution"] = ["width": resolution.width, "height": resolution.height] }
            return params

        case .getQualityMetrics:
            return nil

        case .update(_, let endedAt, let duration, let status):
            var params: Parameters = ["status": status.rawValue]
            if let endedAt { params["endedAt"] = formatter.string(from: endedAt) }
            if let duration { params["duration"] = duration }
            return params
        }
    }
}

// MARK: - CallKitEndpoint (iOS CallKit integration)

enum CallKitEndpoint: APIEndpoint {
    // Register device for CallKit push notifications (with VoIP token)
    case registerDevice(
        deviceToken: String,
        voipToken: String?,
        platform: String,
        deviceId: String?,
        appVersion: String?,
        osVersion: String?,
        sandbox: Bool,
        topics: [String]?
    )

    // Update VoIP token for existing device token
    case updateVoipToken(deviceToken: String, voipToken: String)

    // Unregister device
    case unregisterDevice(deviceToken: String)

    // List user's device tokens
    case listDeviceTokens

    // Get ICE servers for WebRTC
    case getIceServers

    // Report CallKit call result (for analytics)
    case reportResult(
        callId: String,
        answered: Bool,
        duration: Int?
    )

    // Test incoming call (dev only)
    case testIncomingCall(
        callId: String?,
        roomId: String?,
        callerName: String?,
        callerUsername: String?,
        hasVideo: Bool?,
        isGroupCall: Bool?,
        iceServers: [[String: Any]]?
    )

    // Test call event (dev only)
    case testCallEvent(
        callId: String,
        roomId: String?,
        calleeId: String,
        callerId: String,
        eventType: String, // "accepted", "declined", "missed", "ended", "failed"
        metadata: [String: Any]?
    )

    // Call initiated (internal/service-to-service)
    case callInitiated(
        callId: String,
        roomId: String,
        callerId: String,
        calleeIds: [String],
        callerName: String,
        callerUsername: String,
        callerAvatarUrl: String?,
        hasVideo: Bool,
        isGroupCall: Bool
    )

    // Call event (internal/service-to-service)
    case callEvent(
        callId: String,
        roomId: String?,
        calleeId: String,
        callerId: String,
        eventType: String, // "accepted", "declined", "missed", "ended", "failed"
        metadata: [String: Any]?
    )

    // Get VoIP push service stats
    case getStats

    // Cleanup expired device tokens (internal cron)
    case cleanup

    var path: String {
        switch self {
        case .registerDevice:
            return "/v1/callkit/device-token"
        case .updateVoipToken:
            return "/v1/callkit/voip-token"
        case .unregisterDevice:
            return "/v1/callkit/device-token"
        case .listDeviceTokens:
            return "/v1/callkit/device-tokens"
        case .getIceServers:
            return "/v1/callkit/ice-servers"
        case .reportResult:
            return "/v1/callkit/report"
        case .testIncomingCall:
            return "/v1/callkit/test-incoming-call"
        case .testCallEvent:
            return "/v1/callkit/test-call-event"
        case .callInitiated:
            return "/v1/callkit/call-initiated"
        case .callEvent:
            return "/v1/callkit/call-event"
        case .getStats:
            return "/v1/callkit/stats"
        case .cleanup:
            return "/v1/callkit/cleanup"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .listDeviceTokens, .getIceServers, .getStats:
            return .get
        case .registerDevice, .updateVoipToken, .reportResult, .testIncomingCall, .testCallEvent, .callInitiated, .callEvent:
            return .post
        case .unregisterDevice:
            return .delete
        case .cleanup:
            return .post
        }
    }

    var parameters: Parameters? {
        switch self {
        case .registerDevice(let deviceToken, let voipToken, let platform, let deviceId, let appVersion, let osVersion, let sandbox, let topics):
            var params: Parameters = [
                "token": deviceToken,
                "platform": platform,
                "sandbox": sandbox
            ]
            if let voipToken { params["voipToken"] = voipToken }
            if let deviceId { params["deviceId"] = deviceId }
            if let appVersion { params["appVersion"] = appVersion }
            if let osVersion { params["osVersion"] = osVersion }
            if let topics { params["topics"] = topics }
            return params

        case .updateVoipToken(let deviceToken, let voipToken):
            return ["token": deviceToken, "voipToken": voipToken]

        case .unregisterDevice(let deviceToken):
            return ["token": deviceToken]

        case .listDeviceTokens, .getIceServers, .getStats, .cleanup:
            return nil

        case .reportResult(let callId, let answered, let duration):
            var params: Parameters = [
                "callId": callId,
                "answered": answered
            ]
            if let duration { params["duration"] = duration }
            return params

        case .testIncomingCall(let callId, let roomId, let callerName, let callerUsername, let hasVideo, let isGroupCall, let iceServers):
            var params: Parameters = [:]
            if let callId { params["callId"] = callId }
            if let roomId { params["roomId"] = roomId }
            if let callerName { params["callerName"] = callerName }
            if let callerUsername { params["callerUsername"] = callerUsername }
            if let hasVideo { params["hasVideo"] = hasVideo }
            if let isGroupCall { params["isGroupCall"] = isGroupCall }
            if let iceServers { params["iceServers"] = iceServers }
            return params

        case .testCallEvent(let callId, let roomId, let calleeId, let callerId, let eventType, let metadata):
            var params: Parameters = [
                "callId": callId,
                "calleeId": calleeId,
                "callerId": callerId,
                "eventType": eventType
            ]
            if let roomId { params["roomId"] = roomId }
            if let metadata { params["metadata"] = metadata }
            return params

        case .callInitiated(let callId, let roomId, let callerId, let calleeIds, let callerName, let callerUsername, let callerAvatarUrl, let hasVideo, let isGroupCall):
            var params: Parameters = [
                "callId": callId,
                "roomId": roomId,
                "callerId": callerId,
                "calleeIds": calleeIds,
                "callerName": callerName,
                "callerUsername": callerUsername,
                "hasVideo": hasVideo,
                "isGroupCall": isGroupCall
            ]
            if let callerAvatarUrl { params["callerAvatarUrl"] = callerAvatarUrl }
            return params

        case .callEvent(let callId, let roomId, let calleeId, let callerId, let eventType, let metadata):
            var params: Parameters = [
                "callId": callId,
                "calleeId": calleeId,
                "callerId": callerId,
                "eventType": eventType
            ]
            if let roomId { params["roomId"] = roomId }
            if let metadata { params["metadata"] = metadata }
            return params
        }
    }
}

// MARK: - WebSocket Call Signaling (handled via WebSocket, not REST)

// These message types are sent/received over the WebSocket connection
// See WebSocketEndpoint.connect(token:) for connection

struct CallSignalingMessage: Codable {
    let type: CallSignalingType
    let callId: String
    let fromUserId: String
    let toUserId: String?
    let callType: CallType?
    let sdp: String?
    let candidate: IceCandidate?
    let timestamp: Date
}

struct IceCandidate: Codable {
    let candidate: String
    let sdpMid: String?
    let sdpMLineIndex: Int32?
}

// Note: CallType, CallStatus, CallSignalingType are defined in Shared/Enums.swift
// Note: Domain models (Call, CallParticipant, CallUserInfo, etc.) are defined in Data/Mappers/CallMapper.swift
// Note: DTOs are defined in Data/DataSources/Remote/RemoteCallDataSource.swift