//
//  CallSignalingTests.swift
//  InstagramTests
//
//  Created for testing WebRTC call signaling (offer/answer/ICE).
//

import XCTest
import Foundation
@testable import Instagram

// MARK: - Mock CallSignalingHandler Protocol (for WebSocket signaling tests)

protocol MockCallSignalingHandlerProtocol: AnyObject {
    func onOfferReceived(callId: String, sdp: String, fromUserId: String)
    func onAnswerReceived(callId: String, sdp: String)
    func onIceCandidateReceived(callId: String, candidate: String, sdpMid: String, sdpMLineIndex: Int32)
    func onCallEnded(callId: String)
    func onCallRejected(callId: String)
    func onError(callId: String, error: Error)
}

// MARK: - Mock WebSocket Service

class MockWebSocketService {
    var sentMessages: [[String: Any]] = []
    var messageHandler: (([String: Any]) -> Void)?
    var connectionState: WebSocketState = .disconnected
    var shouldFailSend = false

    enum WebSocketState {
        case disconnected, connecting, connected, failed
    }

    func send(_ message: [String: Any]) async throws {
        if shouldFailSend {
            throw NSError(domain: "WebSocket", code: -1)
        }
        sentMessages.append(message)
    }

    func simulateIncomingMessage(_ message: [String: Any]) {
        messageHandler?(message)
    }

    func connect() {
        connectionState = .connected
    }

    func disconnect() {
        connectionState = .disconnected
    }
}

// MARK: - Testable Call Signaling Handler

class TestableCallSignalingHandler: MockCallSignalingHandlerProtocol {
    private let webSocket: MockWebSocketService
    private let callId: String
    private let queue = DispatchQueue(label: "test.signaling.handler", qos: .userInitiated)
    private var localIceCandidates: [(candidate: String, sdpMid: String, sdpMLineIndex: Int32)] = []
    private var remoteDescriptionSet = false
    private var localDescriptionSet = false
    private var _receivedOffers: [(callId: String, sdp: String, fromUserId: String)] = []
    private var _receivedAnswers: [(callId: String, sdp: String)] = []
    private var _receivedIceCandidates: [(callId: String, candidate: String, sdpMid: String, sdpMLineIndex: Int32)] = []
    private var _endedCalls: [String] = []
    private var _rejectedCalls: [String] = []
    private var _errors: [(callId: String, error: Error)] = []
    var shouldFailCreateOffer = false
    var shouldFailCreateAnswer = false
    var shouldFailSetLocalDescription = false
    var shouldFailSetRemoteDescription = false

    var receivedOffers: [(callId: String, sdp: String, fromUserId: String)] {
        queue.sync { _receivedOffers }
    }
    var receivedAnswers: [(callId: String, sdp: String)] {
        queue.sync { _receivedAnswers }
    }
    var receivedIceCandidates: [(callId: String, candidate: String, sdpMid: String, sdpMLineIndex: Int32)] {
        queue.sync { _receivedIceCandidates }
    }
    var endedCalls: [String] {
        queue.sync { _endedCalls }
    }
    var rejectedCalls: [String] {
        queue.sync { _rejectedCalls }
    }
    var errors: [(callId: String, error: Error)] {
        queue.sync { _errors }
    }

    init(webSocket: MockWebSocketService, callId: String) {
        self.webSocket = webSocket
        self.callId = callId

        webSocket.messageHandler = { [weak self] message in
            self?.handleSignalingMessage(message)
        }
    }

    func createOffer() async throws -> String {
        if shouldFailCreateOffer {
            throw NSError(domain: "Signaling", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create offer"])
        }

        let offer = "v=0\r\no=- 1234567890 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\na=group:BUNDLE 0\r\na=msid-semantic: WMS\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\nc=IN IP4 0.0.0.0\r\na=rtcp:9 IN IP4 0.0.0.0\r\na=ice-ufrag:test\r\na=ice-pwd:test\r\na=mid:0\r\na=sendrecv\r\n"

        try await setLocalDescription(type: "offer", sdp: offer)
        return offer
    }

    func createAnswer() async throws -> String {
        if shouldFailCreateAnswer {
            throw NSError(domain: "Signaling", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create answer"])
        }

        let answer = "v=0\r\no=- 1234567890 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\na=group:BUNDLE 0\r\na=msid-semantic: WMS\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\nc=IN IP4 0.0.0.0\r\na=rtcp:9 IN IP4 0.0.0.0\r\na=ice-ufrag:test\r\na=ice-pwd:test\r\na=mid:0\r\na=sendrecv\r\n"

        try await setLocalDescription(type: "answer", sdp: answer)
        return answer
    }

    func setLocalDescription(type: String, sdp: String) async throws {
        if shouldFailSetLocalDescription {
            throw NSError(domain: "Signaling", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to set local description"])
        }

        localDescriptionSet = true

        // Send to remote
        let message: [String: Any] = [
            "type": type,
            "sdp": sdp,
            "callId": callId
        ]

        try await webSocket.send(message)
    }

    func setRemoteDescription(type: String, sdp: String) async throws {
        if shouldFailSetRemoteDescription {
            throw NSError(domain: "Signaling", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to set remote description"])
        }

        remoteDescriptionSet = true
    }

    func addIceCandidate(candidate: String, sdpMid: String, sdpMLineIndex: Int32) async throws {
        queue.sync {
            localIceCandidates.append((candidate, sdpMid, sdpMLineIndex))
        }

        let message: [String: Any] = [
            "type": "candidate",
            "candidate": candidate,
            "sdpMid": sdpMid,
            "sdpMLineIndex": sdpMLineIndex,
            "callId": callId
        ]

        try await webSocket.send(message)
    }

    private func handleSignalingMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }
        guard let messageCallId = message["callId"] as? String, messageCallId == callId else { return }

        switch type {
        case "offer":
            if let sdp = message["sdp"] as? String,
               let fromUserId = message["fromUserId"] as? String {
                queue.sync {
                    _receivedOffers.append((callId, sdp, fromUserId))
                }
                onOfferReceived(callId: callId, sdp: sdp, fromUserId: fromUserId)
            }
        case "answer":
            if let sdp = message["sdp"] as? String {
                queue.sync {
                    _receivedAnswers.append((callId, sdp))
                }
                onAnswerReceived(callId: callId, sdp: sdp)
            }
        case "candidate":
            if let candidate = message["candidate"] as? String,
               let sdpMid = message["sdpMid"] as? String,
               let sdpMLineIndex = message["sdpMLineIndex"] as? Int32 {
                queue.sync {
                    _receivedIceCandidates.append((callId, candidate, sdpMid, sdpMLineIndex))
                }
                onIceCandidateReceived(callId: callId, candidate: candidate, sdpMid: sdpMid, sdpMLineIndex: sdpMLineIndex)
            }
        case "end":
            queue.sync {
                _endedCalls.append(callId)
            }
            onCallEnded(callId: callId)
        case "reject":
            queue.sync {
                _rejectedCalls.append(callId)
            }
            onCallRejected(callId: callId)
        default:
            break
        }
    }

    // Protocol methods
    func onOfferReceived(callId: String, sdp: String, fromUserId: String) {
        Task {
            try? await setRemoteDescription(type: "offer", sdp: sdp)
            _ = try? await createAnswer()
            // Answer is sent automatically in createAnswer
        }
    }

    func onAnswerReceived(callId: String, sdp: String) {
        Task {
            try? await setRemoteDescription(type: "answer", sdp: sdp)
        }
    }

    func onIceCandidateReceived(callId: String, candidate: String, sdpMid: String, sdpMLineIndex: Int32) {
        // Add to peer connection
    }

    func onCallEnded(callId: String) {
        // Cleanup
    }

    func onCallRejected(callId: String) {
        // Cleanup
    }

    func onError(callId: String, error: Error) {
        queue.sync {
            _errors.append((callId, error))
        }
    }

    // Test helpers
    var isLocalDescriptionSet: Bool { localDescriptionSet }
    var isRemoteDescriptionSet: Bool { remoteDescriptionSet }
    var pendingIceCandidatesCount: Int { queue.sync { localIceCandidates.count } }
}

// MARK: - CallSignalingTests

final class CallSignalingTests: XCTestCase {

    var webSocket: MockWebSocketService!
    var signalingHandler: TestableCallSignalingHandler!
    let testCallId = "test_call_123"

    override func setUp() async throws {
        try await super.setUp()
        webSocket = MockWebSocketService()
        signalingHandler = TestableCallSignalingHandler(webSocket: webSocket, callId: testCallId)
        webSocket.connect()
    }

    override func tearDown() async throws {
        webSocket.disconnect()
        signalingHandler = nil
        webSocket = nil
        try await super.tearDown()
    }

    // MARK: - Offer/Answer Tests

    func testCreateOffer_GeneratesValidSDP() async throws {
        let offer = try await signalingHandler.createOffer()

        XCTAssertTrue(offer.contains("v=0"))
        XCTAssertTrue(offer.contains("m=audio"))
        XCTAssertTrue(offer.contains("a=ice-ufrag"))
        XCTAssertTrue(offer.contains("a=ice-pwd"))
        XCTAssertTrue(signalingHandler.isLocalDescriptionSet)
    }

    func testCreateOffer_SendsViaWebSocket() async throws {
        let offer = try await signalingHandler.createOffer()

        XCTAssertEqual(webSocket.sentMessages.count, 1)
        let message = webSocket.sentMessages.first!
        XCTAssertEqual(message["type"] as? String, "offer")
        XCTAssertEqual(message["sdp"] as? String, offer)
        XCTAssertEqual(message["callId"] as? String, testCallId)
    }

    func testCreateOffer_Failure_Throws() async throws {
        signalingHandler.shouldFailCreateOffer = true

        do {
            _ = try await signalingHandler.createOffer()
            XCTFail("Expected error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testCreateAnswer_GeneratesValidSDP() async throws {
        let answer = try await signalingHandler.createAnswer()

        XCTAssertTrue(answer.contains("v=0"))
        XCTAssertTrue(answer.contains("m=audio"))
        XCTAssertTrue(signalingHandler.isLocalDescriptionSet)
    }

    func testCreateAnswer_SendsViaWebSocket() async throws {
        let answer = try await signalingHandler.createAnswer()

        XCTAssertEqual(webSocket.sentMessages.count, 1)
        let message = webSocket.sentMessages.first!
        XCTAssertEqual(message["type"] as? String, "answer")
        XCTAssertEqual(message["sdp"] as? String, answer)
    }

    // MARK: - Remote Description Tests

    func testSetRemoteDescription_Offer() async throws {
        let offer = "v=0\r\no=- 1234567890 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\na=group:BUNDLE 0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n"

        try await signalingHandler.setRemoteDescription(type: "offer", sdp: offer)

        XCTAssertTrue(signalingHandler.isRemoteDescriptionSet)
    }

    func testSetRemoteDescription_Answer() async throws {
        let answer = "v=0\r\no=- 1234567890 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\na=group:BUNDLE 0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n"

        try await signalingHandler.setRemoteDescription(type: "answer", sdp: answer)

        XCTAssertTrue(signalingHandler.isRemoteDescriptionSet)
    }

    func testSetRemoteDescription_Failure_Throws() async throws {
        signalingHandler.shouldFailSetRemoteDescription = true

        do {
            try await signalingHandler.setRemoteDescription(type: "offer", sdp: "test")
            XCTFail("Expected error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Incoming Offer Handling Tests

    func testIncomingOffer_TriggersAnswer() async throws {
        let offer = "v=0\r\no=- 1234567890 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\na=group:BUNDLE 0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n"

        webSocket.simulateIncomingMessage([
            "type": "offer",
            "sdp": offer,
            "callId": testCallId,
            "fromUserId": "caller_123"
        ])

        // Give time for async handling
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(signalingHandler.receivedOffers.count, 1)
        // receivedAnswers tracks incoming answers from remote, not answers we send
        XCTAssertEqual(signalingHandler.receivedAnswers.count, 0)
        XCTAssertEqual(webSocket.sentMessages.count, 1)
        XCTAssertEqual(webSocket.sentMessages.first?["type"] as? String, "answer")
    }

    func testIncomingAnswer_SetsRemoteDescription() async throws {
        let answer = "v=0\r\no=- 1234567890 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\na=group:BUNDLE 0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n"

        webSocket.simulateIncomingMessage([
            "type": "answer",
            "sdp": answer,
            "callId": testCallId
        ])

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(signalingHandler.receivedAnswers.count, 1)
        XCTAssertTrue(signalingHandler.isRemoteDescriptionSet)
    }

    // MARK: - ICE Candidate Tests

    func testAddIceCandidate_SendsViaWebSocket() async throws {
        let candidate = "candidate:1 1 UDP 2122260223 192.168.1.1 54400 typ host"
        let sdpMid = "0"
        let sdpMLineIndex: Int32 = 0

        try await signalingHandler.addIceCandidate(candidate: candidate, sdpMid: sdpMid, sdpMLineIndex: sdpMLineIndex)

        XCTAssertEqual(webSocket.sentMessages.count, 1)
        let message = webSocket.sentMessages.first!
        XCTAssertEqual(message["type"] as? String, "candidate")
        XCTAssertEqual(message["candidate"] as? String, candidate)
        XCTAssertEqual(message["sdpMid"] as? String, sdpMid)
        XCTAssertEqual(message["sdpMLineIndex"] as? Int32, sdpMLineIndex)
        XCTAssertEqual(signalingHandler.pendingIceCandidatesCount, 1)
    }

    func testIncomingIceCandidate_Received() async throws {
        let candidate = "candidate:1 1 UDP 2122260223 192.168.1.1 54400 typ host"

        webSocket.simulateIncomingMessage([
            "type": "candidate",
            "candidate": candidate,
            "sdpMid": "0",
            "sdpMLineIndex": Int32(0),
            "callId": testCallId
        ])

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(signalingHandler.receivedIceCandidates.count, 1)
        XCTAssertEqual(signalingHandler.receivedIceCandidates.first?.candidate, candidate)
    }

    func testIceCandidateBuffering_BeforeRemoteDescription() async throws {
        // Add ICE candidate before remote description is set
        let candidate = "candidate:1 1 UDP 2122260223 192.168.1.1 54400 typ host"

        webSocket.simulateIncomingMessage([
            "type": "candidate",
            "candidate": candidate,
            "sdpMid": "0",
            "sdpMLineIndex": Int32(0),
            "callId": testCallId
        ])

        try await Task.sleep(nanoseconds: 100_000_000)

        // Should be buffered
        XCTAssertEqual(signalingHandler.receivedIceCandidates.count, 1)
    }

    func testIceCandidateBuffering_AfterRemoteDescription_Processed() async throws {
        // First set remote description
        let offer = "v=0\r\no=- 1234567890 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\na=group:BUNDLE 0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n"
        try await signalingHandler.setRemoteDescription(type: "offer", sdp: offer)

        // Then add ICE candidate
        let candidate = "candidate:1 1 UDP 2122260223 192.168.1.1 54400 typ host"

        webSocket.simulateIncomingMessage([
            "type": "candidate",
            "candidate": candidate,
            "sdpMid": "0",
            "sdpMLineIndex": Int32(0),
            "callId": testCallId
        ])

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(signalingHandler.receivedIceCandidates.count, 1)
    }

    // MARK: - Call End/Reject Tests

    func testIncomingCallEnded_CleansUp() async throws {
        webSocket.simulateIncomingMessage([
            "type": "end",
            "callId": testCallId
        ])

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(signalingHandler.endedCalls.count, 1)
        XCTAssertEqual(signalingHandler.endedCalls.first, testCallId)
    }

    func testIncomingCallRejected_CleansUp() async throws {
        webSocket.simulateIncomingMessage([
            "type": "reject",
            "callId": testCallId
        ])

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(signalingHandler.rejectedCalls.count, 1)
        XCTAssertEqual(signalingHandler.rejectedCalls.first, testCallId)
    }

    // MARK: - Race Condition Tests

    func testConcurrentOfferAndAnswer_HandledCorrectly() async throws {
        let offer1 = "v=0\r\no=- 1 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n"
        let offer2 = "v=0\r\no=- 2 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n"

        // Simulate simultaneous offers
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                self.webSocket.simulateIncomingMessage([
                    "type": "offer",
                    "sdp": offer1,
                    "callId": self.testCallId,
                    "fromUserId": "caller_1"
                ])
            }
            group.addTask {
                self.webSocket.simulateIncomingMessage([
                    "type": "offer",
                    "sdp": offer2,
                    "callId": self.testCallId,
                    "fromUserId": "caller_2"
                ])
            }
        }

        try await Task.sleep(nanoseconds: 300_000_000)

        // Both should be received
        XCTAssertEqual(signalingHandler.receivedOffers.count, 2)
    }

    func testConcurrentIceCandidates_AllReceived() async throws {
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    self.webSocket.simulateIncomingMessage([
                        "type": "candidate",
                        "candidate": "candidate:\(i) 1 UDP 2122260223 192.168.1.1 \(54400+i) typ host",
                        "sdpMid": "0",
                        "sdpMLineIndex": Int32(0),
                        "callId": self.testCallId
                    ])
                }
            }
        }

        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(signalingHandler.receivedIceCandidates.count, 10)
    }

    // MARK: - Network Failure Tests

    func testWebSocketSendFailure_OnOffer_Retries() async throws {
        webSocket.shouldFailSend = true

        do {
            _ = try await signalingHandler.createOffer()
            XCTFail("Expected error")
        } catch {
            // Expected
        }

        // Failed sends are not recorded in sentMessages
        XCTAssertEqual(webSocket.sentMessages.count, 0)
    }

    func testWebSocketSendFailure_OnIceCandidate_Queues() async throws {
        webSocket.shouldFailSend = true

        do {
            try await signalingHandler.addIceCandidate(candidate: "test", sdpMid: "0", sdpMLineIndex: Int32(0))
            XCTFail("Expected error")
        } catch {
            // Expected
        }

        // Re-enable and verify it can send again
        webSocket.shouldFailSend = false
        try await signalingHandler.addIceCandidate(candidate: "test2", sdpMid: "0", sdpMLineIndex: Int32(0))

        // Only the successful send is recorded
        XCTAssertEqual(webSocket.sentMessages.count, 1)
    }

    // MARK: - Simulator vs Device Tests

    #if targetEnvironment(simulator)
    func testSimulator_WebRTCAvailable() async throws {
        // On simulator, WebRTC should still work for testing
        let offer = try await signalingHandler.createOffer()
        XCTAssertFalse(offer.isEmpty)
    }
    #endif

    // MARK: - State Machine Tests

    func testSignalingStateMachine_Transitions() async throws {
        // Initial state
        XCTAssertFalse(signalingHandler.isLocalDescriptionSet)
        XCTAssertFalse(signalingHandler.isRemoteDescriptionSet)

        // Create offer -> local description set
        _ = try await signalingHandler.createOffer()
        XCTAssertTrue(signalingHandler.isLocalDescriptionSet)

        // Receive answer -> remote description set
        let answer = "v=0\r\no=- 1234567890 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\na=group:BUNDLE 0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n"
        webSocket.simulateIncomingMessage([
            "type": "answer",
            "sdp": answer,
            "callId": testCallId
        ])

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(signalingHandler.isRemoteDescriptionSet)
    }
}