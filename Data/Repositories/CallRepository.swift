//
//  CallRepository.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Combine

// MARK: - Repository Errors

private enum RepositoryError: Error, LocalizedError {
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "This feature is not yet implemented"
        }
    }
}

// MARK: - CallRepository Implementation

final class CallRepository: CallRepositoryProtocol {
    private let dataSource: RemoteCallDataSourceProtocol
    private let mapper: CallMapper.Type = CallMapper.self

    init(dataSource: RemoteCallDataSourceProtocol) {
        self.dataSource = dataSource
    }

    // MARK: - Call History & Details

    func getCallHistory(page: Int, perPage: Int, type: CallType?, status: CallStatus?) -> AnyPublisher<PaginatedCalls, Error> {
        return dataSource.getCallHistory(page: page, perPage: perPage, type: type, status: status)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func fetchCallHistory() async throws -> [CallHistoryItem] {
        // Use the existing paginated method and convert to CallHistoryItem
        let publisher = dataSource.getCallHistory(page: 1, perPage: 50, type: nil, status: nil)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()

        // Convert to async
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = publisher
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { paginatedCalls in
                        let items = paginatedCalls.items.map { call in
                            // Convert Call to CallHistoryItem
                            // We need to determine the "other user" - for simplicity, use the first participant
                            // In a real app, you'd filter out the current user
                            let otherUser = call.participants?.first?.user ?? CallUserInfo(
                                id: "",
                                username: "",
                                fullName: "",
                                avatarUrl: nil
                            )
                            return CallHistoryItem(
                                id: call.id,
                                otherUserId: otherUser.id,
                                otherUserName: otherUser.fullName,
                                otherUserUsername: otherUser.username,
                                otherUserAvatarURL: otherUser.avatarUrl.flatMap { URL(string: $0) },
                                type: call.callType,
                                direction: .outgoing, // Would need to be determined from call data
                                startedAt: call.startedAt,
                                duration: call.duration.map { TimeInterval($0) },
                                isMissed: call.status == .missed
                            )
                        }
                        continuation.resume(returning: items)
                        cancellable?.cancel()
                    }
                )
        }
    }

    func getCallDetail(callId: String) -> AnyPublisher<Call, Error> {
        return dataSource.getCallDetail(callId: callId)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func deleteCallHistory(id: String) async throws {
        // Call the API to delete a call history item
        // This would need an endpoint - for now, throw not implemented
        throw RepositoryError.notImplemented
    }

    func clearCallHistory() async throws {
        // Call the API to clear all call history
        // This would need an endpoint - for now, throw not implemented
        throw RepositoryError.notImplemented
    }

    // MARK: - Call Management

    func createCall(
        participantIds: [String],
        callType: CallType,
        startedAt: Date,
        endedAt: Date?,
        conversationId: String?,
        maxParticipants: Int?,
        isRecording: Bool?,
        metadata: [String: String]?
    ) -> AnyPublisher<Call, Error> {
        let request = CreateCallRequestDTO(
            participantIds: participantIds,
            callType: callType,
            startedAt: startedAt,
            endedAt: endedAt,
            conversationId: conversationId,
            maxParticipants: maxParticipants,
            isRecording: isRecording,
            metadata: metadata
        )
        return dataSource.createCall(request)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func joinCall(callId: String, deviceType: String?, appVersion: String?) -> AnyPublisher<Call, Error> {
        return dataSource.joinCall(callId: callId, deviceType: deviceType, appVersion: appVersion)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func leaveCall(callId: String, reason: String?) -> AnyPublisher<Void, Error> {
        return dataSource.leaveCall(callId: callId, reason: reason)
    }

    func endCall(callId: String, reason: String?) -> AnyPublisher<Void, Error> {
        return dataSource.endCall(callId: callId, reason: reason)
    }

    func inviteParticipants(callId: String, participantIds: [String]) -> AnyPublisher<Void, Error> {
        return dataSource.inviteParticipants(callId: callId, participantIds: participantIds)
    }

    func kickParticipant(callId: String, targetUserId: String, reason: String?) -> AnyPublisher<Void, Error> {
        return dataSource.kickParticipant(callId: callId, targetUserId: targetUserId, reason: reason)
    }

    func updateParticipant(callId: String, targetUserId: String, isMuted: Bool?, isVideoOff: Bool?, isScreenShare: Bool?) -> AnyPublisher<Void, Error> {
        return dataSource.updateParticipant(callId: callId, targetUserId: targetUserId, isMuted: isMuted, isVideoOff: isVideoOff, isScreenShare: isScreenShare)
    }

    func transferHost(callId: String, newHostId: String) -> AnyPublisher<Void, Error> {
        return dataSource.transferHost(callId: callId, newHostId: newHostId)
    }

    // MARK: - Call Recording

    func getCallRecording(callId: String) -> AnyPublisher<CallRecording, Error> {
        return dataSource.getCallRecording(callId: callId)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    // MARK: - Quality Metrics

    func recordQualityMetrics(
        callId: String,
        participantId: String,
        bitrate: Double,
        packetLoss: Double,
        latency: Double,
        jitter: Double,
        fps: Double?,
        resolution: (width: Int, height: Int)?
    ) -> AnyPublisher<Void, Error> {
        let request = QualityMetricsRequestDTO(
            callId: callId,
            participantId: participantId,
            bitrate: bitrate,
            packetLoss: packetLoss,
            latency: latency,
            jitter: jitter,
            fps: fps,
            resolution: resolution.map { ResolutionDTO(width: $0.width, height: $0.height) }
        )
        return dataSource.recordQualityMetrics(request)
    }

    func getQualityMetrics(callId: String, participantId: String) -> AnyPublisher<CallQualityMetrics, Error> {
        return dataSource.getQualityMetrics(callId: callId, participantId: participantId)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    // MARK: - Update Call Record

    func updateCall(
        callId: String,
        endedAt: Date?,
        duration: Int?,
        status: CallStatus
    ) -> AnyPublisher<Call, Error> {
        return dataSource.updateCall(callId: callId, endedAt: endedAt, duration: duration, status: status)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    // MARK: - CallKit Endpoints

    func registerCallKitDevice(
        deviceToken: String,
        voipToken: String?,
        platform: String,
        deviceId: String?,
        appVersion: String?,
        osVersion: String?,
        sandbox: Bool,
        topics: [String]?
    ) -> AnyPublisher<CallKitRegistration, Error> {
        let request = CallKitRegisterRequestDTO(
            deviceToken: deviceToken,
            voipToken: voipToken,
            platform: platform,
            deviceId: deviceId,
            appVersion: appVersion,
            osVersion: osVersion,
            sandbox: sandbox,
            topics: topics
        )
        return dataSource.registerCallKitDevice(request)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func updateVoipToken(deviceToken: String, voipToken: String) -> AnyPublisher<CallKitRegistration, Error> {
        return dataSource.updateVoipToken(deviceToken: deviceToken, voipToken: voipToken)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func unregisterCallKitDevice(deviceToken: String) -> AnyPublisher<Void, Error> {
        return dataSource.unregisterCallKitDevice(deviceToken: deviceToken)
    }

    func listCallKitDevices() -> AnyPublisher<[CallKitDevice], Error> {
        return dataSource.listCallKitDevices()
            .map { $0.map { self.mapper.map($0) } }
            .eraseToAnyPublisher()
    }

    func getIceServers() -> AnyPublisher<[IceServer], Error> {
        return dataSource.getIceServers()
            .map { $0.map { self.mapper.map($0) } }
            .eraseToAnyPublisher()
    }

    func reportCallKitResult(
        callId: String,
        answered: Bool,
        duration: Int?
    ) -> AnyPublisher<CallKitReportResponse, Error> {
        let request = CallKitReportRequestDTO(
            callId: callId,
            answered: answered,
            duration: duration
        )
        return dataSource.reportCallKitResult(request)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    // MARK: - CallKit Test Endpoints (Dev Only)

    func testIncomingCall(
        callId: String?,
        roomId: String?,
        callerName: String?,
        callerUsername: String?,
        hasVideo: Bool?,
        isGroupCall: Bool?,
        iceServers: [[String: String]]?
    ) -> AnyPublisher<TestCallResult, Error> {
        let request = TestIncomingCallRequestDTO(
            callId: callId,
            roomId: roomId,
            callerName: callerName,
            callerUsername: callerUsername,
            hasVideo: hasVideo,
            isGroupCall: isGroupCall,
            iceServers: iceServers
        )
        return dataSource.testIncomingCall(request)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func testCallEvent(
        callId: String,
        roomId: String?,
        calleeId: String,
        callerId: String,
        eventType: String,
        metadata: [String: String]?
    ) -> AnyPublisher<TestCallEventResult, Error> {
        let request = TestCallEventRequestDTO(
            callId: callId,
            roomId: roomId,
            calleeId: calleeId,
            callerId: callerId,
            eventType: eventType,
            metadata: metadata
        )
        return dataSource.testCallEvent(request)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    // MARK: - CallKit Internal/Service Endpoints

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
    ) -> AnyPublisher<CallInitiatedResult, Error> {
        let request = CallInitiatedRequestDTO(
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
        return dataSource.callInitiated(request)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func callEvent(
        callId: String,
        roomId: String?,
        calleeId: String,
        callerId: String,
        eventType: String,
        metadata: [String: String]?
    ) -> AnyPublisher<CallEventResult, Error> {
        let request = CallEventRequestDTO(
            callId: callId,
            roomId: roomId,
            calleeId: calleeId,
            callerId: callerId,
            eventType: eventType,
            metadata: metadata
        )
        return dataSource.callEvent(request)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    // MARK: - Stats & Cleanup

    func getCallKitStats() -> AnyPublisher<CallKitStats, Error> {
        return dataSource.getCallKitStats()
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func cleanupCallKitDevices() -> AnyPublisher<CleanupResult, Error> {
        return dataSource.cleanupCallKitDevices()
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }
}