//
//  RemoteCallDataSource.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Combine

// MARK: - RemoteCallDataSource Protocol

protocol RemoteCallDataSourceProtocol {
    // Call history & details
    func getCallHistory(page: Int, perPage: Int, type: CallType?, status: CallStatus?) -> AnyPublisher<PaginatedCallsDTO, Error>
    func getCallDetail(callId: String) -> AnyPublisher<CallDTO, Error>

    // Call management
    func createCall(_ request: CreateCallRequestDTO) -> AnyPublisher<CallDTO, Error>
    func joinCall(callId: String, deviceType: String?, appVersion: String?) -> AnyPublisher<CallDTO, Error>
    func leaveCall(callId: String, reason: String?) -> AnyPublisher<Void, Error>
    func endCall(callId: String, reason: String?) -> AnyPublisher<Void, Error>
    func inviteParticipants(callId: String, participantIds: [String]) -> AnyPublisher<Void, Error>
    func kickParticipant(callId: String, targetUserId: String, reason: String?) -> AnyPublisher<Void, Error>
    func updateParticipant(callId: String, targetUserId: String, isMuted: Bool?, isVideoOff: Bool?, isScreenShare: Bool?) -> AnyPublisher<Void, Error>
    func transferHost(callId: String, newHostId: String) -> AnyPublisher<Void, Error>

    // Call recording
    func getCallRecording(callId: String) -> AnyPublisher<CallRecordingDTO, Error>

    // Quality metrics
    func recordQualityMetrics(_ request: QualityMetricsRequestDTO) -> AnyPublisher<Void, Error>
    func getQualityMetrics(callId: String, participantId: String) -> AnyPublisher<QualityMetricsDTO, Error>

    // Update call record
    func updateCall(callId: String, endedAt: Date?, duration: Int?, status: CallStatus) -> AnyPublisher<CallDTO, Error>

    // CallKit endpoints
    func registerCallKitDevice(_ request: CallKitRegisterRequestDTO) -> AnyPublisher<CallKitRegistrationDTO, Error>
    func updateVoipToken(deviceToken: String, voipToken: String) -> AnyPublisher<CallKitRegistrationDTO, Error>
    func unregisterCallKitDevice(deviceToken: String) -> AnyPublisher<Void, Error>
    func listCallKitDevices() -> AnyPublisher<[CallKitDeviceDTO], Error>
    func getIceServers() -> AnyPublisher<[IceServerDTO], Error>
    func reportCallKitResult(_ request: CallKitReportRequestDTO) -> AnyPublisher<CallKitReportResponseDTO, Error>

    // CallKit test endpoints (dev only)
    func testIncomingCall(_ request: TestIncomingCallRequestDTO) -> AnyPublisher<TestCallResultDTO, Error>
    func testCallEvent(_ request: TestCallEventRequestDTO) -> AnyPublisher<TestCallEventResultDTO, Error>

    // CallKit internal/service endpoints
    func callInitiated(_ request: CallInitiatedRequestDTO) -> AnyPublisher<CallInitiatedResultDTO, Error>
    func callEvent(_ request: CallEventRequestDTO) -> AnyPublisher<CallEventResultDTO, Error>

    // Stats & cleanup
    func getCallKitStats() -> AnyPublisher<CallKitStatsDTO, Error>
    func cleanupCallKitDevices() -> AnyPublisher<CleanupResultDTO, Error>
}

// MARK: - RemoteCallDataSource Implementation

final class RemoteCallDataSource: RemoteCallDataSourceProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    // MARK: - Call History & Details

    func getCallHistory(page: Int, perPage: Int, type: CallType?, status: CallStatus?) -> AnyPublisher<PaginatedCallsDTO, Error> {
        let endpoint = CallEndpoint.history(page: page, perPage: perPage, type: type, status: status)
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func getCallDetail(callId: String) -> AnyPublisher<CallDTO, Error> {
        let endpoint = CallEndpoint.detail(callId: callId)
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    // MARK: - Call Management

    func createCall(_ request: CreateCallRequestDTO) -> AnyPublisher<CallDTO, Error> {
        let endpoint = CallEndpoint.create(
            participantIds: request.participantIds,
            callType: request.callType,
            startedAt: request.startedAt,
            endedAt: request.endedAt,
            conversationId: request.conversationId,
            maxParticipants: request.maxParticipants,
            isRecording: request.isRecording,
            metadata: request.metadata
        )
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func joinCall(callId: String, deviceType: String?, appVersion: String?) -> AnyPublisher<CallDTO, Error> {
        let endpoint = CallEndpoint.join(callId: callId, deviceType: deviceType, appVersion: appVersion)
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func leaveCall(callId: String, reason: String?) -> AnyPublisher<Void, Error> {
        let endpoint = CallEndpoint.leave(callId: callId, reason: reason)
        return networkService.requestVoidPublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func endCall(callId: String, reason: String?) -> AnyPublisher<Void, Error> {
        let endpoint = CallEndpoint.end(callId: callId, reason: reason)
        return networkService.requestVoidPublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func inviteParticipants(callId: String, participantIds: [String]) -> AnyPublisher<Void, Error> {
        let endpoint = CallEndpoint.invite(callId: callId, participantIds: participantIds)
        return networkService.requestVoidPublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func kickParticipant(callId: String, targetUserId: String, reason: String?) -> AnyPublisher<Void, Error> {
        let endpoint = CallEndpoint.kick(callId: callId, targetUserId: targetUserId, reason: reason)
        return networkService.requestVoidPublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func updateParticipant(callId: String, targetUserId: String, isMuted: Bool?, isVideoOff: Bool?, isScreenShare: Bool?) -> AnyPublisher<Void, Error> {
        let endpoint = CallEndpoint.updateParticipant(callId: callId, targetUserId: targetUserId, isMuted: isMuted, isVideoOff: isVideoOff, isScreenShare: isScreenShare)
        return networkService.requestVoidPublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func transferHost(callId: String, newHostId: String) -> AnyPublisher<Void, Error> {
        let endpoint = CallEndpoint.transferHost(callId: callId, newHostId: newHostId)
        return networkService.requestVoidPublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    // MARK: - Call Recording

    func getCallRecording(callId: String) -> AnyPublisher<CallRecordingDTO, Error> {
        let endpoint = CallEndpoint.recording(callId: callId)
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    // MARK: - Quality Metrics

    func recordQualityMetrics(_ request: QualityMetricsRequestDTO) -> AnyPublisher<Void, Error> {
        let endpoint = CallEndpoint.qualityMetrics(
            callId: request.callId,
            participantId: request.participantId,
            bitrate: request.bitrate,
            packetLoss: request.packetLoss,
            latency: request.latency,
            jitter: request.jitter,
            fps: request.fps,
            resolution: request.resolution.map { (width: $0.width, height: $0.height) }
        )
        return networkService.requestVoidPublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func getQualityMetrics(callId: String, participantId: String) -> AnyPublisher<QualityMetricsDTO, Error> {
        // Note: The endpoint doesn't support filtering by participantId, we'll fetch all and filter
        let endpoint = CallEndpoint.getQualityMetrics(callId: callId)
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .map { (response: QualityMetricsResponseDTO) in response.data }
            .eraseToAnyPublisher()
    }

    // MARK: - Update Call Record

    func updateCall(callId: String, endedAt: Date?, duration: Int?, status: CallStatus) -> AnyPublisher<CallDTO, Error> {
        let endpoint = CallEndpoint.update(callId: callId, endedAt: endedAt, duration: duration, status: status)
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    // MARK: - CallKit Endpoints

    func registerCallKitDevice(_ request: CallKitRegisterRequestDTO) -> AnyPublisher<CallKitRegistrationDTO, Error> {
        let endpoint = CallKitEndpoint.registerDevice(
            deviceToken: request.deviceToken,
            voipToken: request.voipToken,
            platform: request.platform,
            deviceId: request.deviceId,
            appVersion: request.appVersion,
            osVersion: request.osVersion,
            sandbox: request.sandbox,
            topics: request.topics
        )
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .map { (response: CallKitRegistrationResponseDTO) in response.data }
            .eraseToAnyPublisher()
    }

    func updateVoipToken(deviceToken: String, voipToken: String) -> AnyPublisher<CallKitRegistrationDTO, Error> {
        let endpoint = CallKitEndpoint.updateVoipToken(deviceToken: deviceToken, voipToken: voipToken)
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .map { (response: CallKitRegistrationResponseDTO) in response.data }
            .eraseToAnyPublisher()
    }

    func unregisterCallKitDevice(deviceToken: String) -> AnyPublisher<Void, Error> {
        let endpoint = CallKitEndpoint.unregisterDevice(deviceToken: deviceToken)
        return networkService.requestVoidPublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func listCallKitDevices() -> AnyPublisher<[CallKitDeviceDTO], Error> {
        let endpoint = CallKitEndpoint.listDeviceTokens
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .map { (response: CallKitDeviceListResponseDTO) in response.data.items }
            .eraseToAnyPublisher()
    }

    func getIceServers() -> AnyPublisher<[IceServerDTO], Error> {
        let endpoint = CallKitEndpoint.getIceServers
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .map { (response: IceServersResponseDTO) in response.data.iceServers }
            .eraseToAnyPublisher()
    }

    func reportCallKitResult(_ request: CallKitReportRequestDTO) -> AnyPublisher<CallKitReportResponseDTO, Error> {
        let endpoint = CallKitEndpoint.reportResult(callId: request.callId, answered: request.answered, duration: request.duration)
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    // MARK: - CallKit Test Endpoints (Dev Only)

    func testIncomingCall(_ request: TestIncomingCallRequestDTO) -> AnyPublisher<TestCallResultDTO, Error> {
        let endpoint = CallKitEndpoint.testIncomingCall(
            callId: request.callId,
            roomId: request.roomId,
            callerName: request.callerName,
            callerUsername: request.callerUsername,
            hasVideo: request.hasVideo,
            isGroupCall: request.isGroupCall,
            iceServers: request.iceServers
        )
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .map { (response: TestCallResultResponseDTO) in response.data }
            .eraseToAnyPublisher()
    }

    func testCallEvent(_ request: TestCallEventRequestDTO) -> AnyPublisher<TestCallEventResultDTO, Error> {
        let endpoint = CallKitEndpoint.testCallEvent(
            callId: request.callId,
            roomId: request.roomId,
            calleeId: request.calleeId,
            callerId: request.callerId,
            eventType: request.eventType,
            metadata: request.metadata
        )
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .map { (response: TestCallEventResultResponseDTO) in response.data }
            .eraseToAnyPublisher()
    }

    // MARK: - CallKit Internal/Service Endpoints

    func callInitiated(_ request: CallInitiatedRequestDTO) -> AnyPublisher<CallInitiatedResultDTO, Error> {
        let endpoint = CallKitEndpoint.callInitiated(
            callId: request.callId,
            roomId: request.roomId,
            callerId: request.callerId,
            calleeIds: request.calleeIds,
            callerName: request.callerName,
            callerUsername: request.callerUsername,
            callerAvatarUrl: request.callerAvatarUrl,
            hasVideo: request.hasVideo,
            isGroupCall: request.isGroupCall
        )
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .map { (response: CallInitiatedResultResponseDTO) in response.data }
            .eraseToAnyPublisher()
    }

    func callEvent(_ request: CallEventRequestDTO) -> AnyPublisher<CallEventResultDTO, Error> {
        let endpoint = CallKitEndpoint.callEvent(
            callId: request.callId,
            roomId: request.roomId,
            calleeId: request.calleeId,
            callerId: request.callerId,
            eventType: request.eventType,
            metadata: request.metadata
        )
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .map { (response: CallEventResultResponseDTO) in response.data }
            .eraseToAnyPublisher()
    }

    // MARK: - Stats & Cleanup

    func getCallKitStats() -> AnyPublisher<CallKitStatsDTO, Error> {
        let endpoint = CallKitEndpoint.getStats
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .map { (response: CallKitStatsResponseDTO) in response.data }
            .eraseToAnyPublisher()
    }

    func cleanupCallKitDevices() -> AnyPublisher<CleanupResultDTO, Error> {
        let endpoint = CallKitEndpoint.cleanup
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .map { (response: CleanupResultResponseDTO) in response.data }
            .eraseToAnyPublisher()
    }
}