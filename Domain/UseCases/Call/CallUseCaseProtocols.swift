//
//  CallUseCaseProtocols.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Combine

// MARK: - Call Use Case Protocols

protocol GetCallHistoryUseCaseProtocol {
    func execute(page: Int, perPage: Int, type: CallType?, status: CallStatus?) -> AnyPublisher<PaginatedCalls, Error>
}

protocol GetCallDetailUseCaseProtocol {
    func execute(callId: String) -> AnyPublisher<Call, Error>
}

protocol CreateCallRecordUseCaseProtocol {
    func execute(
        participantIds: [String],
        callType: CallType,
        startedAt: Date,
        endedAt: Date?,
        conversationId: String?,
        maxParticipants: Int?,
        isRecording: Bool?,
        metadata: [String: String]?
    ) -> AnyPublisher<Call, Error>
}

protocol JoinCallUseCaseProtocol {
    func execute(callId: String, deviceType: String?, appVersion: String?) -> AnyPublisher<Call, Error>
}

protocol LeaveCallUseCaseProtocol {
    func execute(callId: String, reason: String?) -> AnyPublisher<Void, Error>
}

protocol EndCallUseCaseProtocol {
    func execute(callId: String, reason: String?) -> AnyPublisher<Void, Error>
}

protocol InviteParticipantsUseCaseProtocol {
    func execute(callId: String, participantIds: [String]) -> AnyPublisher<Void, Error>
}

protocol KickParticipantUseCaseProtocol {
    func execute(callId: String, targetUserId: String, reason: String?) -> AnyPublisher<Void, Error>
}

protocol UpdateParticipantUseCaseProtocol {
    func execute(callId: String, targetUserId: String, isMuted: Bool?, isVideoOff: Bool?, isScreenShare: Bool?) -> AnyPublisher<Void, Error>
}

protocol TransferHostUseCaseProtocol {
    func execute(callId: String, newHostId: String) -> AnyPublisher<Void, Error>
}

protocol GetCallRecordingUseCaseProtocol {
    func execute(callId: String) -> AnyPublisher<CallRecording, Error>
}

protocol RecordQualityMetricsUseCaseProtocol {
    func execute(
        callId: String,
        participantId: String,
        bitrate: Double,
        packetLoss: Double,
        latency: Double,
        jitter: Double,
        fps: Double?,
        resolution: (width: Int, height: Int)?
    ) -> AnyPublisher<Void, Error>
}

protocol GetQualityMetricsUseCaseProtocol {
    func execute(callId: String, participantId: String) -> AnyPublisher<CallQualityMetrics, Error>
}

protocol UpdateCallRecordUseCaseProtocol {
    func execute(
        callId: String,
        endedAt: Date?,
        duration: Int?,
        status: CallStatus
    ) -> AnyPublisher<Call, Error>
}

protocol RegisterCallKitDeviceUseCaseProtocol {
    func execute(
        deviceToken: String,
        voipToken: String?,
        platform: String,
        deviceId: String?,
        appVersion: String?,
        osVersion: String?,
        sandbox: Bool,
        topics: [String]?
    ) -> AnyPublisher<CallKitRegistration, Error>
}

protocol UpdateVoipTokenUseCaseProtocol {
    func execute(deviceToken: String, voipToken: String) -> AnyPublisher<CallKitRegistration, Error>
}

protocol UnregisterCallKitDeviceUseCaseProtocol {
    func execute(deviceToken: String) -> AnyPublisher<Void, Error>
}

protocol ListCallKitDevicesUseCaseProtocol {
    func execute() -> AnyPublisher<[CallKitDevice], Error>
}

protocol GetIceServersUseCaseProtocol {
    func execute() -> AnyPublisher<[IceServer], Error>
}

protocol ReportCallKitResultUseCaseProtocol {
    func execute(callId: String, answered: Bool, duration: Int?) -> AnyPublisher<CallKitReportResponse, Error>
}

// CallKit Test Endpoints (Dev Only)
protocol TestIncomingCallUseCaseProtocol {
    func execute(
        callId: String?,
        roomId: String?,
        callerName: String?,
        callerUsername: String?,
        hasVideo: Bool?,
        isGroupCall: Bool?,
        iceServers: [[String: String]]?
    ) -> AnyPublisher<TestCallResult, Error>
}

protocol TestCallEventUseCaseProtocol {
    func execute(
        callId: String,
        roomId: String?,
        calleeId: String,
        callerId: String,
        eventType: String,
        metadata: [String: String]?
    ) -> AnyPublisher<TestCallEventResult, Error>
}

// CallKit Internal/Service Endpoints
protocol CallInitiatedUseCaseProtocol {
    func execute(
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
}

protocol CallEventUseCaseProtocol {
    func execute(
        callId: String,
        roomId: String?,
        calleeId: String,
        callerId: String,
        eventType: String,
        metadata: [String: String]?
    ) -> AnyPublisher<CallEventResult, Error>
}

// Stats & Cleanup
protocol GetCallKitStatsUseCaseProtocol {
    func execute() -> AnyPublisher<CallKitStats, Error>
}

protocol CleanupCallKitDevicesUseCaseProtocol {
    func execute() -> AnyPublisher<CleanupResult, Error>
}