//
//  CallMapper.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation

// MARK: - Domain Models (defined here to avoid duplication)

// Call
struct Call {
    let id: String
    let participantIds: [String]
    let callType: CallType
    let status: CallStatus
    let startedAt: Date
    let endedAt: Date?
    let duration: Int?
    let createdAt: Date
    let updatedAt: Date
    let participants: [CallParticipant]?
    let conversationId: String?
    let maxParticipants: Int?
    let isRecording: Bool?
    let recordingUrl: String?
}

// Call Participant
struct CallParticipant {
    let userId: String
    let joinedAt: Date?
    let leftAt: Date?
    let user: CallUserInfo
    let isMuted: Bool?
    let isVideoOff: Bool?
    let isScreenSharing: Bool?
    let mediaState: ParticipantMediaState?
}

// Participant Media State
struct ParticipantMediaState {
    let isMuted: Bool
    let isVideoOff: Bool
    let isScreenSharing: Bool
}

// Call User Info
struct CallUserInfo {
    let id: String
    let username: String
    let fullName: String
    let avatarUrl: String?
}

// Paginated Calls
struct PaginatedCalls {
    let items: [Call]
    let page: Int
    let perPage: Int
    let total: Int
    let hasMore: Bool
}

// Call Kit Registration
struct CallKitRegistration {
    let success: Bool
    let deviceId: String
}

// Call Kit Report Response
struct CallKitReportResponse {
    let success: Bool
    let callId: String
}

// Call Kit Device
struct CallKitDevice {
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

// ICE Server
struct IceServer {
    let urls: [String]
    let username: String?
    let credential: String?
}

// Call Kit Stats
struct CallKitStats {
    let service: CallKitServiceStats
    let user: CallKitUserStats
}

struct CallKitServiceStats {
    let totalTokens: Int
    let activeTokens: Int
    let voipTokens: Int
    let sentToday: Int
    let failedToday: Int
}

struct CallKitUserStats {
    let tokensByPlatform: [String: CallKitPlatformStats]
}

struct CallKitPlatformStats {
    let total: Int
    let voip: Int
}

// Test Call Result
struct TestCallResult {
    let callId: String
    let roomId: String
    let result: TestCallResultData
}

struct TestCallResultData {
    let total: Int
    let successful: Int
    let failed: Int
    let invalidTokens: Int
}

// Test Call Event Result
struct TestCallEventResult {
    let eventType: String
    let callId: String
    let result: TestCallEventResultData
}

struct TestCallEventResultData {
    let total: Int
    let successful: Int
    let failed: Int
    let invalidTokens: Int
}

// Call Initiated Result
struct CallInitiatedResult {
    let callId: String
    let calleesCount: Int
    let result: CallInitiatedResultData
}

struct CallInitiatedResultData {
    let total: Int
    let successful: Int
    let failed: Int
    let results: [[String: String]]
    let invalidTokens: [String]
}

// Call Event Result
struct CallEventResult {
    let eventType: String
    let callId: String
    let result: CallEventResultData
}

struct CallEventResultData {
    let total: Int
    let successful: Int
    let failed: Int
    let invalidTokens: Int
}

// Call Recording
struct CallRecording {
    let callId: String
    let recordingUrl: String
    let startedAt: Date
    let endedAt: Date?
    let duration: Int?
    let format: String?
    let size: Int?
}

// Call Quality Metrics
struct CallQualityMetrics {
    let callId: String
    let participantId: String
    let bitrate: Double
    let packetLoss: Double
    let latency: Double
    let jitter: Double
    let fps: Double?
    let resolution: Resolution?
    let timestamp: Date
}

struct Resolution {
    let width: Int
    let height: Int
}

// Cleanup Result
struct CleanupResult {
    let cleanedTokens: Int
}

// MARK: - CallMapper

struct CallMapper {
    nonisolated static func map(_ dto: CallDTO) -> Call {
        return Call(
            id: dto.id,
            participantIds: dto.participantIds,
            callType: dto.callType,
            status: dto.status,
            startedAt: dto.startedAt,
            endedAt: dto.endedAt,
            duration: dto.duration,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            participants: dto.participants?.map(map),
            conversationId: dto.conversationId,
            maxParticipants: dto.maxParticipants,
            isRecording: dto.isRecording,
            recordingUrl: dto.recordingUrl
        )
    }

    nonisolated static func map(_ dto: CallParticipantDTO) -> CallParticipant {
        return CallParticipant(
            userId: dto.userId,
            joinedAt: dto.joinedAt,
            leftAt: dto.leftAt,
            user: map(dto.user),
            isMuted: dto.isMuted,
            isVideoOff: dto.isVideoOff,
            isScreenSharing: dto.isScreenSharing,
            mediaState: dto.mediaState.map(map)
        )
    }

    nonisolated static func map(_ dto: ParticipantMediaStateDTO) -> ParticipantMediaState {
        return ParticipantMediaState(
            isMuted: dto.isMuted,
            isVideoOff: dto.isVideoOff,
            isScreenSharing: dto.isScreenSharing
        )
    }

    nonisolated static func map(_ dto: CallUserInfoDTO) -> CallUserInfo {
        return CallUserInfo(
            id: dto.id,
            username: dto.username,
            fullName: dto.fullName,
            avatarUrl: dto.avatarUrl
        )
    }

    nonisolated static func map(_ dto: PaginatedCallsDTO) -> PaginatedCalls {
        return PaginatedCalls(
            items: dto.items.map(map),
            page: dto.page,
            perPage: dto.perPage,
            total: dto.total,
            hasMore: dto.hasMore
        )
    }

    nonisolated static func map(_ dto: CallKitRegistrationDTO) -> CallKitRegistration {
        return CallKitRegistration(
            success: dto.success,
            deviceId: dto.deviceId
        )
    }

    nonisolated static func map(_ dto: CallKitReportResponseDTO) -> CallKitReportResponse {
        return CallKitReportResponse(
            success: dto.success,
            callId: dto.callId
        )
    }

    nonisolated static func map(_ dto: CallKitDeviceDTO) -> CallKitDevice {
        return CallKitDevice(
            id: dto.id,
            token: dto.token,
            platform: dto.platform,
            deviceId: dto.deviceId,
            appVersion: dto.appVersion,
            osVersion: dto.osVersion,
            voipToken: dto.voipToken,
            sandbox: dto.sandbox,
            topics: dto.topics,
            lastUsedAt: dto.lastUsedAt,
            expiresAt: dto.expiresAt,
            isActive: dto.isActive,
            createdAt: dto.createdAt
        )
    }

    nonisolated static func map(_ dto: IceServerDTO) -> IceServer {
        return IceServer(
            urls: dto.urls,
            username: dto.username,
            credential: dto.credential
        )
    }

    nonisolated static func map(_ dto: CallKitStatsDTO) -> CallKitStats {
        return CallKitStats(
            service: map(dto.service),
            user: map(dto.user)
        )
    }

    nonisolated static func map(_ dto: CallKitServiceStatsDTO) -> CallKitServiceStats {
        return CallKitServiceStats(
            totalTokens: dto.totalTokens,
            activeTokens: dto.activeTokens,
            voipTokens: dto.voipTokens,
            sentToday: dto.sentToday,
            failedToday: dto.failedToday
        )
    }

    nonisolated static func map(_ dto: CallKitUserStatsDTO) -> CallKitUserStats {
        return CallKitUserStats(
            tokensByPlatform: dto.tokensByPlatform.mapValues(map)
        )
    }

    nonisolated static func map(_ dto: CallKitPlatformStatsDTO) -> CallKitPlatformStats {
        return CallKitPlatformStats(
            total: dto.total,
            voip: dto.voip
        )
    }

    nonisolated static func map(_ dto: TestCallResultDTO) -> TestCallResult {
        return TestCallResult(
            callId: dto.callId,
            roomId: dto.roomId,
            result: map(dto.result)
        )
    }

    nonisolated static func map(_ dto: TestCallResultDataDTO) -> TestCallResultData {
        return TestCallResultData(
            total: dto.total,
            successful: dto.successful,
            failed: dto.failed,
            invalidTokens: dto.invalidTokens
        )
    }

    nonisolated static func map(_ dto: TestCallEventResultDTO) -> TestCallEventResult {
        return TestCallEventResult(
            eventType: dto.eventType,
            callId: dto.callId,
            result: map(dto.result)
        )
    }

    nonisolated static func map(_ dto: TestCallEventResultDataDTO) -> TestCallEventResultData {
        return TestCallEventResultData(
            total: dto.total,
            successful: dto.successful,
            failed: dto.failed,
            invalidTokens: dto.invalidTokens
        )
    }

    nonisolated static func map(_ dto: CallInitiatedResultDTO) -> CallInitiatedResult {
        return CallInitiatedResult(
            callId: dto.callId,
            calleesCount: dto.calleesCount,
            result: map(dto.result)
        )
    }

    nonisolated static func map(_ dto: CallInitiatedResultDataDTO) -> CallInitiatedResultData {
        return CallInitiatedResultData(
            total: dto.total,
            successful: dto.successful,
            failed: dto.failed,
            results: dto.results,
            invalidTokens: dto.invalidTokens
        )
    }

    nonisolated static func map(_ dto: CallEventResultDTO) -> CallEventResult {
        return CallEventResult(
            eventType: dto.eventType,
            callId: dto.callId,
            result: map(dto.result)
        )
    }

    nonisolated static func map(_ dto: CallEventResultDataDTO) -> CallEventResultData {
        return CallEventResultData(
            total: dto.total,
            successful: dto.successful,
            failed: dto.failed,
            invalidTokens: dto.invalidTokens
        )
    }

    nonisolated static func map(_ dto: CallRecordingDTO) -> CallRecording {
        return CallRecording(
            callId: dto.callId,
            recordingUrl: dto.recordingUrl,
            startedAt: dto.startedAt,
            endedAt: dto.endedAt,
            duration: dto.duration,
            format: dto.format,
            size: dto.size
        )
    }

    nonisolated static func map(_ dto: QualityMetricsDTO) -> CallQualityMetrics {
        return CallQualityMetrics(
            callId: dto.callId,
            participantId: dto.participantId,
            bitrate: dto.bitrate,
            packetLoss: dto.packetLoss,
            latency: dto.latency,
            jitter: dto.jitter,
            fps: dto.fps,
            resolution: dto.resolution.map { Resolution(width: $0.width, height: $0.height) },
            timestamp: dto.timestamp
        )
    }

    nonisolated static func map(_ dto: CleanupResultDTO) -> CleanupResult {
        return CleanupResult(
            cleanedTokens: dto.cleanedTokens
        )
    }
}

// Note: CallType, CallStatus are defined in Shared/Enums.swift
// Note: DTOs are defined in Data/DTOs/CallDTO.swift