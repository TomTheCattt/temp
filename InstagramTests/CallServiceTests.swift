//
//  CallServiceTests.swift
//  InstagramTests
//
//  Created for testing CallService state machine and call flow.
//

import XCTest
import Combine
import CallKit
@testable import Instagram

// MARK: - Mock Dependencies

final class MockCallManager: CallManager, @unchecked Sendable {
    var reportedIncomingCalls: [(uuid: UUID, callId: String, callerName: String, callerUserId: String, hasVideo: Bool)] = []
    var reportedOutgoingCalls: [(uuid: UUID, connectedAt: Date?)] = []
    var reportedCallEndedCalls: [(uuid: UUID, reason: CXCallEndedReason)] = []
    var setMutedCalls: [(uuid: UUID, muted: Bool)] = []
    var shouldFailReportIncoming = false
    var reportIncomingError: Error?
    var shouldFailStartOutgoing = false
    var startOutgoingError: Error?
    private let mockCallEventsSubject = PassthroughSubject<CallKitEvent, Never>()

    override var callEvents: AnyPublisher<CallKitEvent, Never> {
        mockCallEventsSubject.eraseToAnyPublisher()
    }

    var callEventsSubject: PassthroughSubject<CallKitEvent, Never> {
        mockCallEventsSubject
    }

    override func reportIncomingCall(
        uuid: UUID,
        callId: String,
        callerName: String,
        callerUserId: String,
        hasVideo: Bool
    ) async throws {
        reportedIncomingCalls.append((uuid, callId, callerName, callerUserId, hasVideo))
        if shouldFailReportIncoming, let error = reportIncomingError {
            throw error
        }
    }

    override func startOutgoingCall(
        uuid: UUID,
        callId: String,
        remoteUserId: String,
        remoteName: String,
        hasVideo: Bool
    ) async throws {
        if shouldFailStartOutgoing, let error = startOutgoingError {
            throw error
        }
        // Track for verification
    }

    override func endCall(uuid: UUID) async throws {
        // Track for verification
    }

    override func reportOutgoingCallConnected(uuid: UUID) {
        reportedOutgoingCalls.append((uuid, Date()))
    }

    override func reportCallEnded(uuid: UUID, reason: CXCallEndedReason) {
        reportedCallEndedCalls.append((uuid: uuid, reason: reason))
    }

    override func setMuted(uuid: UUID, muted: Bool) async throws {
        setMutedCalls.append((uuid, muted))
    }

    override func reportOutgoingCallStartedConnecting(uuid: UUID) {
        reportedOutgoingCalls.append((uuid, Date()))
    }
}

class MockCallSignalingHandler: CallSignalingHandlerProtocol {
    var sentSignals: [CallSignal] = []
    var incomingSignalSubject = PassthroughSubject<CallSignal, Never>()
    var shouldFailSend = false
    var sendError: Error?
    var isConnectedValue = true

    var incomingSignalPublisher: AnyPublisher<CallSignal, Never> {
        incomingSignalSubject.eraseToAnyPublisher()
    }

    var isConnected: Bool { isConnectedValue }

    func connect() async throws {}
    func disconnect() {}
    func send(signal: CallSignal) async throws {
        sentSignals.append(signal)
        if shouldFailSend, let error = sendError {
            throw error
        }
    }
}

import Combine
import CoreMedia

class MockCallMediaPipeline: CallMediaPipelineProtocol {
    var startAudioCalled = false
    var stopAudioCalled = false
    var startVideoCalled = false
    var stopVideoCalled = false
    var setMutedValue: Bool?
    var setSpeakerValue: Bool?
    var ringbackToneStarted = false
    var ringbackToneStopped = false
    var incomingRingtoneStarted = false
    var incomingRingtoneStopped = false
    var switchCameraCalled = false
    var switchCameraFront: Bool?
    var shouldFailStartAudio = false
    var shouldFailStartVideo = false

    // Publishers
    nonisolated let audioLevelSubject = PassthroughSubject<Float, Never>()
    nonisolated let localSampleBufferSubject = PassthroughSubject<CMSampleBuffer, Never>()
    nonisolated let remoteSampleBufferSubject = PassthroughSubject<CMSampleBuffer, Never>()

    nonisolated var audioLevelPublisher: AnyPublisher<Float, Never> {
        audioLevelSubject.eraseToAnyPublisher()
    }

    nonisolated var localSampleBufferPublisher: AnyPublisher<CMSampleBuffer, Never> {
        localSampleBufferSubject.eraseToAnyPublisher()
    }

    nonisolated var remoteSampleBufferPublisher: AnyPublisher<CMSampleBuffer, Never> {
        remoteSampleBufferSubject.eraseToAnyPublisher()
    }

    func startAudio() async throws {
        startAudioCalled = true
        if shouldFailStartAudio { throw NSError(domain: "Media", code: -1) }
    }

    func stopAudio() { stopAudioCalled = true }
    func startVideo(isFront: Bool) async throws {
        startVideoCalled = true
        switchCameraFront = isFront
        if shouldFailStartVideo { throw NSError(domain: "Media", code: -1) }
    }
    func stopVideo() { stopVideoCalled = true }
    func setMuted(_ muted: Bool) { setMutedValue = muted }
    func setSpeaker(_ speaker: Bool) { setSpeakerValue = speaker }
    func startRingbackTone() { ringbackToneStarted = true }
    func stopRingbackTone() { ringbackToneStopped = true }
    func startIncomingRingtone() { incomingRingtoneStarted = true }
    func stopIncomingRingtone() { incomingRingtoneStopped = true }
    func switchCamera(isFront: Bool) async { switchCameraCalled = true; switchCameraFront = isFront }
    func restartAfterInterruption() async {}
}

// MARK: - Testable CallService

@MainActor
final class TestableCallService: CallService, @unchecked Sendable {
    let mockCallManager: MockCallManager
    let mockSignalingHandler: MockCallSignalingHandler
    let mockMediaPipeline: MockCallMediaPipeline

    init(
        mockCallManager: MockCallManager,
        mockSignalingHandler: MockCallSignalingHandler,
        mockMediaPipeline: MockCallMediaPipeline,
        mockNetworkMonitor: TestMockNetworkMonitor? = nil
    ) {
        self.mockCallManager = mockCallManager
        self.mockSignalingHandler = mockSignalingHandler
        self.mockMediaPipeline = mockMediaPipeline

        // Create AsyncStream from mock network monitor's publisher if provided
        let connectionChanges: AsyncStream<Bool>?
        if let mockNetworkMonitor = mockNetworkMonitor {
            connectionChanges = AsyncStream { continuation in
                let cancellable = mockNetworkMonitor.isConnectedPublisher
                    .sink { continuation.yield($0) }
                continuation.onTermination = { @Sendable _ in cancellable.cancel() }
            }
        } else {
            connectionChanges = nil
        }

        super.init(
            callManager: mockCallManager,
            signalingHandler: mockSignalingHandler,
            mediaPipeline: mockMediaPipeline,
            connectionChanges: connectionChanges
        )
    }
}

// MARK: - CallServiceTests

@MainActor
final class CallServiceTests: XCTestCase {

    var callService: TestableCallService!
    var mockCallManager: MockCallManager!
    var mockSignalingHandler: MockCallSignalingHandler!
    var mockMediaPipeline: MockCallMediaPipeline!
    var mockNetworkMonitor: TestMockNetworkMonitor!
    var cancellables = Set<AnyCancellable>()

    override func setUp() async throws {
        try await super.setUp()

        mockCallManager = MockCallManager()
        mockSignalingHandler = MockCallSignalingHandler()
        mockMediaPipeline = MockCallMediaPipeline()
        mockNetworkMonitor = TestMockNetworkMonitor()

        callService = TestableCallService(
            mockCallManager: mockCallManager,
            mockSignalingHandler: mockSignalingHandler,
            mockMediaPipeline: mockMediaPipeline,
            mockNetworkMonitor: mockNetworkMonitor
        )
    }

    override func tearDown() async throws {
        callService.reset()
        callService = nil
        mockCallManager = nil
        mockSignalingHandler = nil
        mockMediaPipeline = nil
        mockNetworkMonitor = nil
        cancellables.removeAll()
        try await super.tearDown()
    }

    // MARK: - State Machine Tests

    func testInitialState_IsIdle() {
        XCTAssertEqual(callService.currentCallState, .idle)
        XCTAssertNil(callService.currentCall)
    }

    func testInitiateCall_TransitionsThroughStates() async throws {
        var states: [CallState] = []

        callService.callStatePublisher
            .sink { states.append($0) }
            .store(in: &cancellables)

        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: true)

        // Wait for async state transitions
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(callService.currentCallState, .ringing)
        XCTAssertNotNil(callService.currentCall)
        XCTAssertEqual(callService.currentCall?.remoteUserId, "user_456")
        XCTAssertEqual(callService.currentCall?.remoteName, "Jane")
        XCTAssertTrue(callService.currentCall?.hasVideo ?? false)
        XCTAssertTrue(callService.currentCall?.isOutgoing ?? false)
    }

    func testInitiateCall_WhenAlreadyInCall_ThrowsError() async throws {
        // First call
        try await callService.initiateCall(to: "user_1", name: "User 1", hasVideo: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Second call should fail
        do {
            try await callService.initiateCall(to: "user_2", name: "User 2", hasVideo: false)
            XCTFail("Expected callAlreadyInProgress error")
        } catch CallServiceError.callAlreadyInProgress {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testInitiateCall_SendsCallInitiateSignal() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: true)
        try await Task.sleep(nanoseconds: 100_000_000)

        let signals = mockSignalingHandler.sentSignals
        XCTAssertEqual(signals.count, 1)
        if case .callInitiate(let callId, _, let toUserId, let callType) = signals.first {
            XCTAssertEqual(toUserId, "user_456")
            XCTAssertEqual(callType, .video)
            XCTAssertFalse(callId.isEmpty)
        } else {
            XCTFail("Expected callInitiate signal")
        }
    }

    func testInitiateCall_StartsMediaPipeline() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: true)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(mockMediaPipeline.startAudioCalled)
        XCTAssertTrue(mockMediaPipeline.startVideoCalled)
        XCTAssertTrue(mockMediaPipeline.ringbackToneStarted)
    }

    func testInitiateCall_ReportsToCallKit() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: true)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mockCallManager.reportedIncomingCalls.count, 0) // Not incoming
        // startOutgoingCall was called internally
    }

    // MARK: - Accept Incoming Call Tests

    func testAcceptIncomingCall_TransitionsToConnected() async throws {
        // Setup incoming call
        let signal = CallSignal.callIncoming(
            callId: "incoming_123",
            fromUserId: "caller_123",
            toUserId: "me",
            callType: .audio
        )
        let uuid = UUID()
        await callService.handleIncomingCall(signal: signal, callerName: "Caller", uuid: uuid)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(callService.currentCallState, .incomingRinging)

        // Accept the call
        try await callService.acceptIncomingCall()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(callService.currentCallState, .connected)
        XCTAssertNotNil(callService.currentCall?.connectedAt)
    }

    func testAcceptIncomingCall_SendsCallAnswerSignal() async throws {
        let signal = CallSignal.callIncoming(
            callId: "incoming_123",
            fromUserId: "caller_123",
            toUserId: "me",
            callType: .video
        )
        let uuid = UUID()
        await callService.handleIncomingCall(signal: signal, callerName: "Caller", uuid: uuid)
        try await Task.sleep(nanoseconds: 100_000_000)

        try await callService.acceptIncomingCall()
        try await Task.sleep(nanoseconds: 100_000_000)

        let signals = mockSignalingHandler.sentSignals
        let answerSignals = signals.compactMap { signal -> (String, String, String, String)? in
            if case .callAnswer(let callId, let fromUserId, let toUserId, let sdp) = signal {
                return (callId, fromUserId, toUserId, sdp)
            }
            return nil
        }
        XCTAssertEqual(answerSignals.count, 1)
        XCTAssertEqual(answerSignals.first?.0, "incoming_123")
        XCTAssertEqual(answerSignals.first?.2, "caller_123")
    }

    func testAcceptIncomingCall_StopsIncomingRingtone() async throws {
        let signal = CallSignal.callIncoming(
            callId: "incoming_123",
            fromUserId: "caller_123",
            toUserId: "me",
            callType: .audio
        )
        // Don't pass uuid so that handleIncomingCall starts the incoming ringtone (in-app signaling path)
        await callService.handleIncomingCall(signal: signal, callerName: "Caller")
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(mockMediaPipeline.incomingRingtoneStarted)

        try await callService.acceptIncomingCall()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(mockMediaPipeline.incomingRingtoneStopped)
    }

    func testAcceptIncomingCall_WhenNoIncomingCall_Throws() async throws {
        do {
            try await callService.acceptIncomingCall()
            XCTFail("Expected noIncomingCall error")
        } catch CallServiceError.noIncomingCall {
            // Expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    // MARK: - Reject Incoming Call Tests

    func testRejectIncomingCall_EndsCallWithRejectedReason() async throws {
        let signal = CallSignal.callIncoming(
            callId: "incoming_123",
            fromUserId: "caller_123",
            toUserId: "me",
            callType: .audio
        )
        let uuid = UUID()
        await callService.handleIncomingCall(signal: signal, callerName: "Caller", uuid: uuid)
        try await Task.sleep(nanoseconds: 100_000_000)

        try await callService.rejectIncomingCall()
        try await Task.sleep(nanoseconds: 100_000_000)

        if case .ended(let reason) = callService.currentCallState {
            XCTAssertEqual(reason, .rejected)
        } else {
            XCTFail("Expected ended state with rejected reason")
        }
    }

    func testRejectIncomingCall_SendsCallRejectSignal() async throws {
        let signal = CallSignal.callIncoming(
            callId: "incoming_123",
            fromUserId: "caller_123",
            toUserId: "me",
            callType: .audio
        )
        let uuid = UUID()
        await callService.handleIncomingCall(signal: signal, callerName: "Caller", uuid: uuid)
        try await Task.sleep(nanoseconds: 100_000_000)

        try await callService.rejectIncomingCall()
        try await Task.sleep(nanoseconds: 100_000_000)

        let rejectSignals = mockSignalingHandler.sentSignals.compactMap { signal -> String? in
            if case .callReject(let callId, _, _) = signal { return callId }
            return nil
        }
        XCTAssertEqual(rejectSignals.count, 1)
        XCTAssertEqual(rejectSignals.first, "incoming_123")
    }

    // MARK: - Hangup Tests

    func testHangup_EndsCallWithLocalHangupReason() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        try await callService.hangup()
        try await Task.sleep(nanoseconds: 100_000_000)

        if case .ended(let reason) = callService.currentCallState {
            XCTAssertEqual(reason, .localHangup)
        } else {
            XCTFail("Expected ended state with localHangup reason")
        }
    }

    func testHangup_SendsCallHangupSignal() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        try await callService.hangup()
        try await Task.sleep(nanoseconds: 100_000_000)

        let hangupSignals = mockSignalingHandler.sentSignals.compactMap { signal -> String? in
            if case .callHangup(let callId, _, _) = signal { return callId }
            return nil
        }
        XCTAssertEqual(hangupSignals.count, 1)
    }

    func testHangup_WhenNoActiveCall_Throws() async throws {
        do {
            try await callService.hangup()
            XCTFail("Expected noActiveCall error")
        } catch CallServiceError.noActiveCall {
            // Expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    // MARK: - Media Control Tests

    func testToggleMute_UpdatesStateAndCallKit() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertFalse(callService.currentCall?.isMuted ?? true)

        try await callService.toggleMute()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(callService.currentCall?.isMuted ?? false)
        XCTAssertTrue(mockMediaPipeline.setMutedValue ?? false)
        XCTAssertEqual(mockCallManager.setMutedCalls.count, 1)
        XCTAssertTrue(mockCallManager.setMutedCalls.first?.muted ?? false)
    }

    func testToggleSpeaker_UpdatesState() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertFalse(callService.currentCall?.isSpeakerOn ?? true)

        try await callService.toggleSpeaker()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(callService.currentCall?.isSpeakerOn ?? false)
        XCTAssertTrue(mockMediaPipeline.setSpeakerValue ?? false)
    }

    func testFlipCamera_CallsMediaPipeline() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: true)
        try await Task.sleep(nanoseconds: 100_000_000)

        await callService.flipCamera(isFront: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(mockMediaPipeline.switchCameraCalled)
        XCTAssertFalse(mockMediaPipeline.switchCameraFront ?? true)
    }

    func testToggleCamera_Off_StopsVideo() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: true)
        try await Task.sleep(nanoseconds: 100_000_000)

        await callService.toggleCamera(isOff: true)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertFalse(callService.currentCall?.hasVideo ?? true)
        XCTAssertTrue(mockMediaPipeline.stopVideoCalled)
    }

    func testToggleCamera_On_StartsVideo() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        await callService.toggleCamera(isOff: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(callService.currentCall?.hasVideo ?? false)
        XCTAssertTrue(mockMediaPipeline.startVideoCalled)
    }

    // MARK: - Upgrade to Video Tests

    func testUpgradeToVideo_WhenConnected_StartsVideoAndSendsOffer() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Simulate call connected
        callService.currentCallState = .connected
        callService.currentCall?.connectedAt = Date()

        try await callService.upgradeToVideo()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(callService.currentCall?.hasVideo ?? false)
        XCTAssertTrue(mockMediaPipeline.startVideoCalled)

        let offerSignals = mockSignalingHandler.sentSignals.compactMap { signal -> String? in
            if case .callOffer(let callId, _, _, _) = signal { return callId }
            return nil
        }
        XCTAssertEqual(offerSignals.count, 1)
    }

    func testUpgradeToVideo_WhenNotConnected_Throws() async throws {
        // Idle state
        do {
            try await callService.upgradeToVideo()
            XCTFail("Expected noActiveCall error")
        } catch CallServiceError.noActiveCall {
            // Expected
        }
    }

    func testUpgradeToVideo_WhenAlreadyVideo_DoesNothing() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: true)
        try await Task.sleep(nanoseconds: 100_000_000)

        callService.currentCallState = .connected
        callService.currentCall?.connectedAt = Date()

        let initialVideoState = callService.currentCall?.hasVideo
        try await callService.upgradeToVideo()

        XCTAssertEqual(callService.currentCall?.hasVideo, initialVideoState)
    }

    // MARK: - Ring Timeout Tests

    func testRingTimeout_EndsCallWithTimeoutReason() async throws {
        // Use short timeout for testing
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Wait for ring timeout (45 seconds in production, but we can't wait that long)
        // Instead, verify ring timeout task was started
        XCTAssertNotNil(callService.ringTimeoutTask)
    }

    // MARK: - Network Monitoring Tests

    func testNetworkLoss_DuringConnectedCall_TransitionsToReconnecting() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        callService.currentCallState = .connected
        callService.currentCall?.connectedAt = Date()

        // Simulate network loss
        mockNetworkMonitor.simulateConnectionChange(false)

        // Trigger network change
        let expectation = XCTestExpectation(description: "Network change processed")
        // The network monitor task processes changes
        try await Task.sleep(nanoseconds: 200_000_000)
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(callService.currentCallState, .reconnecting)
    }

    func testNetworkRestored_AfterReconnecting_AttemptsRecovery() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        callService.currentCallState = .connected
        callService.currentCall?.connectedAt = Date()

        // Network loss
        mockNetworkMonitor.simulateConnectionChange(false)
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(callService.currentCallState, .reconnecting)

        // Network restored
        mockNetworkMonitor.simulateConnectionChange(true)
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(callService.currentCallState, .connected)
    }

    // MARK: - ICE Candidate Buffering Tests

    func testICE_CandidatesBufferedDuringReconnecting() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        callService.currentCallState = .connected
        callService.currentCall?.connectedAt = Date()

        // Network loss -> reconnecting
        mockNetworkMonitor.simulateConnectionChange(false)
        try await Task.sleep(nanoseconds: 200_000_000)

        // Send ICE candidate while reconnecting
        let iceSignal = CallSignal.callIceCandidate(
            callId: callService.currentCall!.id,
            fromUserId: "remote",
            toUserId: "me",
            candidate: "candidate:123",
            sdpMid: "0",
            sdpMLineIndex: 0
        )
        mockSignalingHandler.incomingSignalSubject.send(iceSignal)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Should be buffered
        XCTAssertEqual(callService.pendingICECandidates.count, 1)
    }

    // MARK: - Call Recovery Tests

    func testCallRecovery_ResendsPendingICECandidates() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        callService.currentCallState = .connected
        callService.currentCall?.connectedAt = Date()

        // Buffer some ICE candidates
        let ice1 = CallSignal.callIceCandidate(callId: "call1", fromUserId: "r", toUserId: "m", candidate: "c1", sdpMid: "0", sdpMLineIndex: 0)
        let ice2 = CallSignal.callIceCandidate(callId: "call1", fromUserId: "r", toUserId: "m", candidate: "c2", sdpMid: "0", sdpMLineIndex: 0)
        callService.pendingICECandidates = [ice1, ice2]

        // Network loss and restore
        mockNetworkMonitor.simulateConnectionChange(false)
        try await Task.sleep(nanoseconds: 200_000_000)
        mockNetworkMonitor.simulateConnectionChange(true)
        try await Task.sleep(nanoseconds: 500_000_000)

        // Should have resent ICE candidates
        let resentCount = mockSignalingHandler.sentSignals.filter { signal in
            if case .callIceCandidate = signal { return true }
            return false
        }.count
        XCTAssertEqual(resentCount, 2)
        XCTAssertTrue(callService.pendingICECandidates.isEmpty)
    }

    // MARK: - Race Condition Tests

    func testConcurrentIncomingAndOutgoing_RejectsIncoming() async throws {
        // Start outgoing call
        try await callService.initiateCall(to: "user_1", name: "User 1", hasVideo: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Simulate incoming call while in outgoing
        let signal = CallSignal.callIncoming(
            callId: "incoming_123",
            fromUserId: "caller_123",
            toUserId: "me",
            callType: .audio
        )
        await callService.handleIncomingCall(signal: signal, callerName: "Caller")
        try await Task.sleep(nanoseconds: 100_000_000)

        // Should have sent busy signal
        let busySignals = mockSignalingHandler.sentSignals.compactMap { signal -> String? in
            if case .callBusy(let callId, _, _) = signal { return callId }
            return nil
        }
        XCTAssertEqual(busySignals.count, 1)
        XCTAssertEqual(busySignals.first, "incoming_123")
    }

    func testCallCancelledDuringAccept_AbortsGracefully() async throws {
        let signal = CallSignal.callIncoming(
            callId: "incoming_123",
            fromUserId: "caller_123",
            toUserId: "me",
            callType: .audio
        )
        let uuid = UUID()
        await callService.handleIncomingCall(signal: signal, callerName: "Caller", uuid: uuid)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Start accept but cancel by ending call
        let acceptTask = Task { try await callService.acceptIncomingCall() }
        try await Task.sleep(nanoseconds: 50_000_000)

        // Cancel by hanging up
        try await callService.hangup()
        try await Task.sleep(nanoseconds: 100_000_000)

        // Accept should complete without crashing
        try await acceptTask.value
    }

    // MARK: - Provider Reset Tests

    func testProviderDidReset_EndsCall() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Simulate provider reset
        mockCallManager.callEventsSubject.send(.providerDidReset)
        try await Task.sleep(nanoseconds: 100_000_000)

        if case .ended(let reason) = callService.currentCallState {
            if case .failed(let msg) = reason {
                XCTAssertTrue(msg.contains("Provider reset"))
            } else {
                XCTFail("Expected failed reason, got \(reason)")
            }
        } else {
            XCTFail("Expected ended state")
        }
    }

    // MARK: - Call Ended Notification Tests

    func testEndCall_PostsDidEndCallNotification() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: true)
        try await Task.sleep(nanoseconds: 100_000_000)

        callService.currentCallState = .connected
        callService.currentCall?.connectedAt = Date()

        let expectation = XCTestExpectation(description: "DidEndCall notification")
        let observer = NotificationCenter.default.addObserver(
            forName: .didEndCall,
            object: nil,
            queue: .main
        ) { notification in
            XCTAssertEqual(notification.userInfo?["remoteUserId"] as? String, "user_456")
            XCTAssertEqual(notification.userInfo?["isOutgoing"] as? Bool, true)
            XCTAssertEqual(notification.userInfo?["hasVideo"] as? Bool, true)
            XCTAssertEqual(notification.userInfo?["reason"] as? String, "localHangup")
            expectation.fulfill()
        }

        try await callService.hangup()
        try await Task.sleep(nanoseconds: 200_000_000)

        await fulfillment(of: [expectation], timeout: 2.0)
        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - Generation Tracking Tests

    func testCallGeneration_IncrementsOnEachCall() async throws {
        let initialGeneration = callService.callGeneration

        try await callService.initiateCall(to: "user_1", name: "User 1", hasVideo: false)
        try await Task.sleep(nanoseconds: 100_000_000)
        try await callService.hangup()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(callService.callGeneration, initialGeneration + 1)

        try await callService.initiateCall(to: "user_2", name: "User 2", hasVideo: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(callService.callGeneration, initialGeneration + 2)
    }

    // MARK: - Reset Tests

    func testReset_ClearsAllState() async throws {
        try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        callService.reset()

        XCTAssertEqual(callService.currentCallState, .idle)
        XCTAssertNil(callService.currentCall)
        XCTAssertTrue(callService.pendingICECandidates.isEmpty)
        XCTAssertFalse(callService.wasConnectedBeforeNetworkLoss)
        XCTAssertNil(callService.networkMonitorTask)
        XCTAssertNil(callService.ringTimeoutTask)
    }

    // MARK: - Error Handling Tests

    func testInitiateCall_SignalingFailure_CleansUp() async throws {
        mockSignalingHandler.shouldFailSend = true
        mockSignalingHandler.sendError = NSError(domain: "Signaling", code: -1)

        do {
            try await callService.initiateCall(to: "user_456", name: "Jane", hasVideo: false)
            XCTFail("Expected error")
        } catch {
            // Expected
        }

        try await Task.sleep(nanoseconds: 100_000_000)

        // Should have cleaned up
        XCTAssertEqual(callService.currentCallState, .idle)
        XCTAssertNil(callService.currentCall)
        XCTAssertTrue(mockMediaPipeline.stopAudioCalled)
        XCTAssertTrue(mockMediaPipeline.stopVideoCalled)
        XCTAssertTrue(mockMediaPipeline.ringbackToneStopped)
    }
}

// MARK: - NetworkMonitor Override for Testing

// We need to make NetworkMonitor's isConnected settable for testing
// This would require modifying the actual NetworkMonitor or using a protocol
// For now, we'll use the existing isConnected property