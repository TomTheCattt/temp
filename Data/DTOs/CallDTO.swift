//
//  CallDTO.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation

// MARK: - Call DTOs

nonisolated struct CallDTO: Codable {
    let id: String
    let participantIds: [String]
    let callType: CallType
    let status: CallStatus
    let startedAt: Date
    let endedAt: Date?
    let duration: Int?
    let createdAt: Date
    let updatedAt: Date
    let participants: [CallParticipantDTO]?
    let conversationId: String?
    let maxParticipants: Int?
    let isRecording: Bool?
    let recordingUrl: String?
}

nonisolated struct CallParticipantDTO: Codable {
    let userId: String
    let joinedAt: Date?
    let leftAt: Date?
    let user: CallUserInfoDTO
    let isMuted: Bool?
    let isVideoOff: Bool?
    let isScreenSharing: Bool?
    let mediaState: ParticipantMediaStateDTO?
}

nonisolated struct ParticipantMediaStateDTO: Codable {
    let isMuted: Bool
    let isVideoOff: Bool
    let isScreenSharing: Bool
}

nonisolated struct CallUserInfoDTO: Codable {
    let id: String
    let username: String
    let fullName: String
    let avatarUrl: String?
}

nonisolated struct PaginatedCallsDTO: Codable {
    let items: [CallDTO]
    let page: Int
    let perPage: Int
    let total: Int
    let hasMore: Bool
}

// MARK: - Request DTOs

nonisolated struct CreateCallRequestDTO: Codable {
    let participantIds: [String]
    let callType: CallType
    let startedAt: Date
    let endedAt: Date?
    let conversationId: String?
    let maxParticipants: Int?
    let isRecording: Bool?
    let metadata: [String: String]?
}

nonisolated struct UpdateCallRequestDTO: Codable {
    let endedAt: Date?
    let duration: Int?
    let status: CallStatus
}

// MARK: - CallKit Request/Response DTOs

struct CallKitRegisterRequestDTO: Codable {
    let deviceToken: String
    let voipToken: String?
    let platform: String
    let deviceId: String?
    let appVersion: String?
    let osVersion: String?
    let sandbox: Bool
    let topics: [String]?
}

struct CallKitReportRequestDTO: Codable {
    let callId: String
    let answered: Bool
    let duration: Int?
}

// CallKit Device
nonisolated struct CallKitDeviceDTO: Codable {
    let id: String
    let token: String
    let platform: String
    let deviceId: String?
    let appVersion: String?
    let osVersion: String?
    let voipToken: String?
    let sandbox: Bool
    let topics: [String]
    let lastUsedAt: Date?
    let expiresAt: Date?
    let isActive: Bool
    let createdAt: Date
}

nonisolated struct CallKitDeviceListResponseDTO: Codable {
    let success: Bool
    let data: CallKitDeviceListDataDTO
    let error: String?
    let message: String?
}

nonisolated struct CallKitDeviceListDataDTO: Codable {
    let items: [CallKitDeviceDTO]
}

// ICE Servers
nonisolated struct IceServerDTO: Codable {
    let urls: [String]
    let username: String?
    let credential: String?
}

nonisolated struct IceServersResponseDTO: Codable {
    let success: Bool
    let data: IceServersDataDTO
    let error: String?
    let message: String?
}

nonisolated struct IceServersDataDTO: Codable {
    let iceServers: [IceServerDTO]
}

// CallKit Stats
nonisolated struct CallKitStatsDTO: Codable {
    let service: CallKitServiceStatsDTO
    let user: CallKitUserStatsDTO
}

nonisolated struct CallKitServiceStatsDTO: Codable {
    let totalTokens: Int
    let activeTokens: Int
    let voipTokens: Int
    let sentToday: Int
    let failedToday: Int
}

nonisolated struct CallKitUserStatsDTO: Codable {
    let tokensByPlatform: [String: CallKitPlatformStatsDTO]
}

nonisolated struct CallKitPlatformStatsDTO: Codable {
    let total: Int
    let voip: Int
}

nonisolated struct CallKitStatsResponseDTO: Codable {
    let success: Bool
    let data: CallKitStatsDTO
    let error: String?
    let message: String?
}

// Cleanup
nonisolated struct CleanupResultDTO: Codable {
    let cleanedTokens: Int
}

nonisolated struct CleanupResultResponseDTO: Codable {
    let success: Bool
    let data: CleanupResultDTO
    let error: String?
    let message: String?
}

// Test Incoming Call
nonisolated struct TestIncomingCallRequestDTO: Codable {
    let callId: String?
    let roomId: String?
    let callerName: String?
    let callerUsername: String?
    let hasVideo: Bool?
    let isGroupCall: Bool?
    let iceServers: [[String: String]]?
}

nonisolated struct TestCallResultDTO: Codable {
    let callId: String
    let roomId: String
    let result: TestCallResultDataDTO
}

nonisolated struct TestCallResultDataDTO: Codable {
    let total: Int
    let successful: Int
    let failed: Int
    let invalidTokens: Int
}

nonisolated struct TestCallResultResponseDTO: Codable {
    let success: Bool
    let data: TestCallResultDTO
    let error: String?
    let message: String?
}

// Test Call Event
nonisolated struct TestCallEventRequestDTO: Codable {
    let callId: String
    let roomId: String?
    let calleeId: String
    let callerId: String
    let eventType: String // "accepted", "declined", "missed", "ended", "failed"
    let metadata: [String: String]?
}

nonisolated struct TestCallEventResultDTO: Codable {
    let eventType: String
    let callId: String
    let result: TestCallEventResultDataDTO
}

nonisolated struct TestCallEventResultDataDTO: Codable {
    let total: Int
    let successful: Int
    let failed: Int
    let invalidTokens: Int
}

nonisolated struct TestCallEventResultResponseDTO: Codable {
    let success: Bool
    let data: TestCallEventResultDTO
    let error: String?
    let message: String?
}

// Call Initiated (internal)
nonisolated struct CallInitiatedRequestDTO: Codable {
    let callId: String
    let roomId: String
    let callerId: String
    let calleeIds: [String]
    let callerName: String
    let callerUsername: String
    let callerAvatarUrl: String?
    let hasVideo: Bool
    let isGroupCall: Bool
}

nonisolated struct CallInitiatedResultDTO: Codable {
    let callId: String
    let calleesCount: Int
    let result: CallInitiatedResultDataDTO
}

nonisolated struct CallInitiatedResultDataDTO: Codable {
    let total: Int
    let successful: Int
    let failed: Int
    let results: [[String: String]]
    let invalidTokens: [String]
}

nonisolated struct CallInitiatedResultResponseDTO: Codable {
    let success: Bool
    let data: CallInitiatedResultDTO
    let error: String?
    let message: String?
}

// Call Event (internal)
nonisolated struct CallEventRequestDTO: Codable {
    let callId: String
    let roomId: String?
    let calleeId: String
    let callerId: String
    let eventType: String // "accepted", "declined", "missed", "ended", "failed"
    let metadata: [String: String]?
}

nonisolated struct CallEventResultDTO: Codable {
    let eventType: String
    let callId: String
    let result: CallEventResultDataDTO
}

nonisolated struct CallEventResultDataDTO: Codable {
    let total: Int
    let successful: Int
    let failed: Int
    let invalidTokens: Int
}

nonisolated struct CallEventResultResponseDTO: Codable {
    let success: Bool
    let data: CallEventResultDTO
    let error: String?
    let message: String?
}

// Call Recording
nonisolated struct CallRecordingDTO: Codable {
    let callId: String
    let recordingUrl: String
    let startedAt: Date
    let endedAt: Date?
    let duration: Int?
    let format: String?
    let size: Int?
}

nonisolated struct CallRecordingResponseDTO: Codable {
    let success: Bool
    let data: CallRecordingDTO
    let error: String?
    let message: String?
}

// Quality Metrics
nonisolated struct QualityMetricsRequestDTO: Codable {
    let callId: String
    let participantId: String
    let bitrate: Double
    let packetLoss: Double
    let latency: Double
    let jitter: Double
    let fps: Double?
    let resolution: ResolutionDTO?
}

nonisolated struct ResolutionDTO: Codable {
    let width: Int
    let height: Int
}

nonisolated struct QualityMetricsDTO: Codable {
    let callId: String
    let participantId: String
    let bitrate: Double
    let packetLoss: Double
    let latency: Double
    let jitter: Double
    let fps: Double?
    let resolution: ResolutionDTO?
    let timestamp: Date
}

nonisolated struct QualityMetricsResponseDTO: Codable {
    let success: Bool
    let data: QualityMetricsDTO
    let error: String?
    let message: String?
}

// Response wrappers
nonisolated struct CallResponseDTO: Codable {
    let success: Bool
    let data: CallDTO
    let error: String?
    let message: String?
}

nonisolated struct PaginatedCallsResponseDTO: Codable {
    let success: Bool
    let data: PaginatedCallsDTO
    let error: String?
    let message: String?
}

nonisolated struct CallKitRegistrationResponseDTO: Codable {
    let success: Bool
    let data: CallKitRegistrationDTO
    let error: String?
    let message: String?
}

nonisolated struct CallKitRegistrationDTO: Codable {
    let success: Bool
    let deviceId: String
}

nonisolated struct CallKitReportResponseDTO: Codable {
    let success: Bool
    let callId: String
}

// Empty response for endpoints that return 204
nonisolated struct EmptyResponseDTO: Codable {
    let success: Bool
}