//
//  CallUseCases.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Combine

// MARK: - Call Use Cases

// Get Call History Use Case
struct GetCallHistoryUseCase: GetCallHistoryUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(page: Int = 1, perPage: Int = 20, type: CallType? = nil, status: CallStatus? = nil) -> AnyPublisher<PaginatedCalls, Error> {
        return repository.getCallHistory(page: page, perPage: perPage, type: type, status: status)
    }
}

// Get Call Detail Use Case
struct GetCallDetailUseCase: GetCallDetailUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(callId: String) -> AnyPublisher<Call, Error> {
        return repository.getCallDetail(callId: callId)
    }
}

// Create Call Record Use Case
struct CreateCallRecordUseCase: CreateCallRecordUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        participantIds: [String],
        callType: CallType,
        startedAt: Date,
        endedAt: Date?,
        conversationId: String? = nil,
        maxParticipants: Int? = nil,
        isRecording: Bool? = nil,
        metadata: [String: String]? = nil
    ) -> AnyPublisher<Call, Error> {
        guard participantIds.count >= 2 else {
            return Fail(error: CallError.insufficientParticipants)
                .eraseToAnyPublisher()
        }

        return repository.createCall(
            participantIds: participantIds,
            callType: callType,
            startedAt: startedAt,
            endedAt: endedAt,
            conversationId: conversationId,
            maxParticipants: maxParticipants,
            isRecording: isRecording,
            metadata: metadata
        )
    }
}

// Join Call Use Case
struct JoinCallUseCase: JoinCallUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(callId: String, deviceType: String? = nil, appVersion: String? = nil) -> AnyPublisher<Call, Error> {
        return repository.joinCall(callId: callId, deviceType: deviceType, appVersion: appVersion)
    }
}

// Leave Call Use Case
struct LeaveCallUseCase: LeaveCallUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(callId: String, reason: String? = nil) -> AnyPublisher<Void, Error> {
        return repository.leaveCall(callId: callId, reason: reason)
    }
}

// End Call Use Case
struct EndCallUseCase: EndCallUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(callId: String, reason: String? = nil) -> AnyPublisher<Void, Error> {
        return repository.endCall(callId: callId, reason: reason)
    }
}

// Invite Participants Use Case
struct InviteParticipantsUseCase: InviteParticipantsUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(callId: String, participantIds: [String]) -> AnyPublisher<Void, Error> {
        guard !participantIds.isEmpty else {
            return Fail(error: CallError.invalidParticipants)
                .eraseToAnyPublisher()
        }

        return repository.inviteParticipants(callId: callId, participantIds: participantIds)
    }
}

// Kick Participant Use Case
struct KickParticipantUseCase: KickParticipantUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(callId: String, targetUserId: String, reason: String? = nil) -> AnyPublisher<Void, Error> {
        return repository.kickParticipant(callId: callId, targetUserId: targetUserId, reason: reason)
    }
}

// Update Participant Use Case
struct UpdateParticipantUseCase: UpdateParticipantUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(callId: String, targetUserId: String, isMuted: Bool?, isVideoOff: Bool?, isScreenShare: Bool?) -> AnyPublisher<Void, Error> {
        return repository.updateParticipant(callId: callId, targetUserId: targetUserId, isMuted: isMuted, isVideoOff: isVideoOff, isScreenShare: isScreenShare)
    }
}

// Transfer Host Use Case
struct TransferHostUseCase: TransferHostUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(callId: String, newHostId: String) -> AnyPublisher<Void, Error> {
        return repository.transferHost(callId: callId, newHostId: newHostId)
    }
}

// Get Call Recording Use Case
struct GetCallRecordingUseCase: GetCallRecordingUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(callId: String) -> AnyPublisher<CallRecording, Error> {
        return repository.getCallRecording(callId: callId)
    }
}

// Record Quality Metrics Use Case
struct RecordQualityMetricsUseCase: RecordQualityMetricsUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        callId: String,
        participantId: String,
        bitrate: Double,
        packetLoss: Double,
        latency: Double,
        jitter: Double,
        fps: Double? = nil,
        resolution: (width: Int, height: Int)? = nil
    ) -> AnyPublisher<Void, Error> {
        return repository.recordQualityMetrics(
            callId: callId,
            participantId: participantId,
            bitrate: bitrate,
            packetLoss: packetLoss,
            latency: latency,
            jitter: jitter,
            fps: fps,
            resolution: resolution
        )
    }
}

// Get Quality Metrics Use Case
struct GetQualityMetricsUseCase: GetQualityMetricsUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(callId: String, participantId: String) -> AnyPublisher<CallQualityMetrics, Error> {
        return repository.getQualityMetrics(callId: callId, participantId: participantId)
    }
}

// Update Call Record Use Case
struct UpdateCallRecordUseCase: UpdateCallRecordUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        callId: String,
        endedAt: Date?,
        duration: Int?,
        status: CallStatus
    ) -> AnyPublisher<Call, Error> {
        return repository.updateCall(
            callId: callId,
            endedAt: endedAt,
            duration: duration,
            status: status
        )
    }
}

// Register CallKit Device Use Case
struct RegisterCallKitDeviceUseCase: RegisterCallKitDeviceUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        deviceToken: String,
        voipToken: String? = nil,
        platform: String,
        deviceId: String? = nil,
        appVersion: String? = nil,
        osVersion: String? = nil,
        sandbox: Bool = false,
        topics: [String]? = nil
    ) -> AnyPublisher<CallKitRegistration, Error> {
        return repository.registerCallKitDevice(
            deviceToken: deviceToken,
            voipToken: voipToken,
            platform: platform,
            deviceId: deviceId,
            appVersion: appVersion,
            osVersion: osVersion,
            sandbox: sandbox,
            topics: topics
        )
    }
}

// Update VoIP Token Use Case
struct UpdateVoipTokenUseCase: UpdateVoipTokenUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(deviceToken: String, voipToken: String) -> AnyPublisher<CallKitRegistration, Error> {
        return repository.updateVoipToken(deviceToken: deviceToken, voipToken: voipToken)
    }
}

// Unregister CallKit Device Use Case
struct UnregisterCallKitDeviceUseCase: UnregisterCallKitDeviceUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(deviceToken: String) -> AnyPublisher<Void, Error> {
        return repository.unregisterCallKitDevice(deviceToken: deviceToken)
    }
}

// List CallKit Devices Use Case
struct ListCallKitDevicesUseCase: ListCallKitDevicesUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute() -> AnyPublisher<[CallKitDevice], Error> {
        return repository.listCallKitDevices()
    }
}

// Get ICE Servers Use Case
struct GetIceServersUseCase: GetIceServersUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute() -> AnyPublisher<[IceServer], Error> {
        return repository.getIceServers()
    }
}

// Report CallKit Result Use Case
struct ReportCallKitResultUseCase: ReportCallKitResultUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(callId: String, answered: Bool, duration: Int?) -> AnyPublisher<CallKitReportResponse, Error> {
        return repository.reportCallKitResult(
            callId: callId,
            answered: answered,
            duration: duration
        )
    }
}

// Test Incoming Call Use Case (Dev Only)
struct TestIncomingCallUseCase: TestIncomingCallUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        callId: String? = nil,
        roomId: String? = nil,
        callerName: String? = nil,
        callerUsername: String? = nil,
        hasVideo: Bool? = nil,
        isGroupCall: Bool? = nil,
        iceServers: [[String: String]]? = nil
    ) -> AnyPublisher<TestCallResult, Error> {
        return repository.testIncomingCall(
            callId: callId,
            roomId: roomId,
            callerName: callerName,
            callerUsername: callerUsername,
            hasVideo: hasVideo,
            isGroupCall: isGroupCall,
            iceServers: iceServers
        )
    }
}

// Test Call Event Use Case (Dev Only)
struct TestCallEventUseCase: TestCallEventUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        callId: String,
        roomId: String? = nil,
        calleeId: String,
        callerId: String,
        eventType: String,
        metadata: [String: String]? = nil
    ) -> AnyPublisher<TestCallEventResult, Error> {
        return repository.testCallEvent(
            callId: callId,
            roomId: roomId,
            calleeId: calleeId,
            callerId: callerId,
            eventType: eventType,
            metadata: metadata
        )
    }
}

// Call Initiated Use Case (Internal)
struct CallInitiatedUseCase: CallInitiatedUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        callId: String,
        roomId: String,
        callerId: String,
        calleeIds: [String],
        callerName: String,
        callerUsername: String,
        callerAvatarUrl: String? = nil,
        hasVideo: Bool,
        isGroupCall: Bool
    ) -> AnyPublisher<CallInitiatedResult, Error> {
        return repository.callInitiated(
            callId: callId,
            roomId: roomId,
            callerId: callerId,
            calleeIds: calleeIds,
            callerName: callerName,
            callerUsername: callerUsername,
            callerAvatarUrl: callerAvatarUrl,
            hasVideo: hasVideo,
            isGroupCall: isGroupCall
        )
    }
}

// Call Event Use Case (Internal)
struct CallEventUseCase: CallEventUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        callId: String,
        roomId: String? = nil,
        calleeId: String,
        callerId: String,
        eventType: String,
        metadata: [String: String]? = nil
    ) -> AnyPublisher<CallEventResult, Error> {
        return repository.callEvent(
            callId: callId,
            roomId: roomId,
            calleeId: calleeId,
            callerId: callerId,
            eventType: eventType,
            metadata: metadata
        )
    }
}

// Get CallKit Stats Use Case
struct GetCallKitStatsUseCase: GetCallKitStatsUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute() -> AnyPublisher<CallKitStats, Error> {
        return repository.getCallKitStats()
    }
}

// Cleanup CallKit Devices Use Case
struct CleanupCallKitDevicesUseCase: CleanupCallKitDevicesUseCaseProtocol {
    private let repository: CallRepositoryProtocol

    init(repository: CallRepositoryProtocol) {
        self.repository = repository
    }

    func execute() -> AnyPublisher<CleanupResult, Error> {
        return repository.cleanupCallKitDevices()
    }
}

// MARK: - Call Errors

enum CallError: Error, LocalizedError {
    case insufficientParticipants
    case invalidParticipants
    case callNotFound
    case callAlreadyEnded
    case invalidCallState
    case signalingFailed
    case deviceRegistrationFailed
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .insufficientParticipants:
            return "At least 2 participants required for a call"
        case .invalidParticipants:
            return "Invalid participants list"
        case .callNotFound:
            return "Call not found"
        case .callAlreadyEnded:
            return "Call has already ended"
        case .invalidCallState:
            return "Invalid call state for this operation"
        case .signalingFailed:
            return "WebSocket signaling failed"
        case .deviceRegistrationFailed:
            return "Failed to register device for CallKit"
        case .unauthorized:
            return "Not authorized to perform this action"
        }
    }
}

// Note: CallError is defined here
// Note: CallRepositoryProtocol is defined in Data/Repositories/CallRepository.swift
// Note: Domain models (Call, CallParticipant, CallUserInfo, PaginatedCalls, CallKitRegistration, CallKitReportResponse, CallKitDevice, IceServer, CallKitStats, TestCallResult, TestCallEventResult, CallInitiatedResult, CallEventResult, CallRecording, CallQualityMetrics, CleanupResult) are defined in Data/Mappers/CallMapper.swift
// Note: CallType, CallStatus are defined in Shared/Enums.swift