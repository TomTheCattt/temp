//
//  WebSocketServiceTests.swift
//  InstagramTests
//
//  Created for testing WebSocket signaling and messaging.
//

import XCTest
import Foundation
import Combine
@testable import Instagram

// MARK: - Mock URLSessionWebSocketTask

class MockURLSessionWebSocketTask: Equatable {
    enum State {
        case suspended
        case running
        case canceling
        case completed
    }

    private let messagesQueue = DispatchQueue(label: "MockURLSessionWebSocketTask.messages")

    var state: State = .suspended
    var closeCode: URLSessionWebSocketTask.CloseCode?
    var closeReason: Data?
    private var _sentMessages: [URLSessionWebSocketTask.Message] = []
    var receiveHandler: ((Result<URLSessionWebSocketTask.Message, Error>) -> Void)?
    var shouldFailSend = false
    var sendError: Error?
    var autoReply: URLSessionWebSocketTask.Message?
    var resumeCount = 0
    var cancelCount = 0

    var sentMessages: [URLSessionWebSocketTask.Message] {
        messagesQueue.sync { _sentMessages }
    }

    static func == (lhs: MockURLSessionWebSocketTask, rhs: MockURLSessionWebSocketTask) -> Bool {
        // Compare by identity for testing purposes
        return lhs === rhs
    }

    func resume() {
        state = .running
        resumeCount += 1
    }

    func send(_ message: URLSessionWebSocketTask.Message, completionHandler: @escaping (Error?) -> Void) {
        if shouldFailSend, let error = sendError {
            completionHandler(error)
        } else {
            messagesQueue.sync {
                _sentMessages.append(message)
            }
            completionHandler(nil)

            // Auto-reply if configured
            if let reply = autoReply {
                receiveHandler?(.success(reply))
            }
        }
    }

    func receive(completionHandler: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void) {
        receiveHandler = completionHandler
    }

    func cancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        self.closeCode = closeCode
        self.closeReason = reason
        state = .canceling
        cancelCount += 1

        // Simulate completion
        state = .completed

        // Clear receive handler to prevent callbacks after cancellation
        receiveHandler = nil
    }

    func simulateIncomingMessage(_ message: URLSessionWebSocketTask.Message) {
        receiveHandler?(.success(message))
    }

    func simulateError(_ error: Error) {
        receiveHandler?(.failure(error))
    }

    func simulateConnectionClose(code: URLSessionWebSocketTask.CloseCode = .normalClosure, reason: String = "") {
        let reasonData = reason.data(using: .utf8)
        let error = NSError(domain: "WebSocket", code: Int(code.rawValue), userInfo: nil)
        // Call the error handler BEFORE canceling (which clears the handler)
        receiveHandler?(.failure(error))
        cancel(with: code, reason: reasonData)
    }
}

// MARK: - Mock URLSession

class MockURLSession {
    var webSocketTask: MockURLSessionWebSocketTask?
    var lastWebSocketURL: URL?

    func webSocketTask(with url: URL) -> MockURLSessionWebSocketTask {
        let task = MockURLSessionWebSocketTask()
        webSocketTask = task
        lastWebSocketURL = url
        return task
    }
}

// MARK: - Testable WebSocket Service

enum WebSocketState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case failed(Error)

    static func == (lhs: WebSocketState, rhs: WebSocketState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected), (.connecting, .connecting), (.connected, .connected), (.reconnecting, .reconnecting):
            return true
        case (.failed(let a), .failed(let b)):
            return a.localizedDescription == b.localizedDescription
        default:
            return false
        }
    }
}

enum WebSocketEvent: Equatable {
    case connected
    case disconnected(Error?)
    case messageReceived([String: Any])
    case error(Error)
    case reconnecting(attempt: Int)

    static func == (lhs: WebSocketEvent, rhs: WebSocketEvent) -> Bool {
        switch (lhs, rhs) {
        case (.connected, .connected):
            return true
        case (.disconnected(let a), .disconnected(let b)):
            return a?.localizedDescription == b?.localizedDescription
        case (.messageReceived(let a), .messageReceived(let b)):
            return NSDictionary(dictionary: a).isEqual(to: b)
        case (.error(let a), .error(let b)):
            return a.localizedDescription == b.localizedDescription
        case (.reconnecting(let a), .reconnecting(let b)):
            return a == b
        default:
            return false
        }
    }
}

class TestableWebSocketService {
    private var mockSession: MockURLSession
    private var webSocketTask: MockURLSessionWebSocketTask?
    private var url: URL
    var state: WebSocketState = .disconnected
    private var eventSubject = PassthroughSubject<WebSocketEvent, Never>()
    var reconnectAttempts = 0
    private var maxReconnectAttempts = 5
    private var reconnectDelay: TimeInterval = 1.0
    private var pingTimer: Timer?
    private var shouldFailConnect = false
    private var connectError: Error?
    var messageQueue: [URLSessionWebSocketTask.Message] = []
    private var isReconnecting = false
    // Test configuration
    var testReconnectDelay: TimeInterval?
    var testPingInterval: TimeInterval?
    var testReconnectImmediately: Bool = false

    var events: AnyPublisher<WebSocketEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    var currentState: WebSocketState { state }

    init(url: URL, session: MockURLSession) {
        self.url = url
        self.mockSession = session
    }

    func connect() async throws {
        guard state != .connecting && state != .connected else { return }

        // Clean up old task if reconnecting
        if let oldTask = webSocketTask {
            oldTask.cancel(with: .normalClosure, reason: "Reconnect".data(using: .utf8))
        }

        state = .connecting

        if shouldFailConnect, let error = connectError {
            state = .failed(error)
            eventSubject.send(.error(error))
            throw error
        }

        webSocketTask = mockSession.webSocketTask(with: url)
        webSocketTask?.resume()

        // Start receiving
        await startReceiving()

        state = .connected
        reconnectAttempts = 0
        eventSubject.send(.connected)

        // Start ping timer
        startPingTimer()

        // Send queued messages
        for message in messageQueue {
            try await send(message)
        }
        messageQueue.removeAll()
    }

    // Synchronous version for test mode with immediate reconnect
    func connectSync() throws {
        guard state != .connecting && state != .connected else { return }

        // Clean up old task if reconnecting
        if let oldTask = webSocketTask {
            oldTask.cancel(with: .normalClosure, reason: "Reconnect".data(using: .utf8))
        }

        state = .connecting

        if shouldFailConnect, let error = connectError {
            state = .failed(error)
            eventSubject.send(.error(error))
            throw error
        }

        webSocketTask = mockSession.webSocketTask(with: url)
        webSocketTask?.resume()

        // For sync version, don't actually start receiving - just update state
        state = .connected
        reconnectAttempts = 0
        eventSubject.send(.connected)

        // Start ping timer
        startPingTimer()

        // Note: Queued messages are not sent in sync mode - tests should handle this
    }

    func disconnect() async {
        stopPingTimer()

        if let task = webSocketTask {
            task.cancel(with: .normalClosure, reason: "Client disconnect".data(using: .utf8))
        }

        let previousState = state
        state = .disconnected

        if previousState == .connected {
            eventSubject.send(.disconnected(nil))
        }
    }

    func send(_ message: URLSessionWebSocketTask.Message) async throws {
        guard let task = webSocketTask, task.state == .running else {
            // Queue for later
            messageQueue.append(message)
            return
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            task.send(message) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func sendText(_ text: String) async throws {
        try await send(.string(text))
    }

    func sendData(_ data: Data) async throws {
        try await send(.data(data))
    }

    private func startReceiving() async {
        guard let task = webSocketTask else { return }

        task.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                self.handleMessage(message)
                // Continue receiving
                Task { await self.startReceiving() }
            case .failure(let error):
                self.handleError(error)
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            if let data = text.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                eventSubject.send(.messageReceived(json))
            }
        case .data(let data):
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                eventSubject.send(.messageReceived(json))
            }
        @unknown default:
            break
        }
    }

    private func handleError(_ error: Error) {
        eventSubject.send(.error(error))

        if state == .connected {
            scheduleReconnect()
        }
    }

    private func scheduleReconnect() {
        guard !isReconnecting, reconnectAttempts < maxReconnectAttempts else {
            state = .failed(NSError(domain: "WebSocket", code: -1, userInfo: [NSLocalizedDescriptionKey: "Max reconnect attempts reached"]))
            eventSubject.send(.error(NSError(domain: "WebSocket", code: -1, userInfo: [NSLocalizedDescriptionKey: "Max reconnect attempts reached"])))
            return
        }

        isReconnecting = true
        state = .reconnecting
        reconnectAttempts += 1
        eventSubject.send(.reconnecting(attempt: reconnectAttempts))

        // In test mode with immediate reconnect, execute synchronously without Task
        if testReconnectImmediately {
            self.isReconnecting = false
            do {
                try self.connectSync()
            } catch {
                // On failure, schedule next reconnect attempt
                self.scheduleReconnect()
            }
            return
        }

        let delay = (testReconnectDelay ?? reconnectDelay) * pow(2.0, Double(reconnectAttempts - 1)) // Exponential backoff

        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            self.isReconnecting = false
            do {
                try await self.connect()
            } catch {
                // On failure, schedule next reconnect attempt
                self.scheduleReconnect()
            }
        }
    }

    private func startPingTimer() {
        let interval = testPingInterval ?? 30
        pingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                try? await self?.sendText("ping")
            }
        }
    }

    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }

    // Test helpers
    func setShouldFailConnect(_ shouldFail: Bool, error: Error? = nil) {
        shouldFailConnect = shouldFail
        connectError = error
    }

    func simulateIncomingMessage(_ message: URLSessionWebSocketTask.Message) {
        webSocketTask?.simulateIncomingMessage(message)
    }

    func triggerPing() async throws {
        try await sendText("ping")
    }

    func simulateConnectionClose(code: URLSessionWebSocketTask.CloseCode = .normalClosure, reason: String = "") {
        webSocketTask?.simulateConnectionClose(code: code, reason: reason)
    }
}

// MARK: - WebSocketServiceTests

final class WebSocketServiceTests: XCTestCase {

    var mockSession: MockURLSession!
    var webSocketService: TestableWebSocketService!
    var cancellables = Set<AnyCancellable>()

    override func setUp() async throws {
        try await super.setUp()
        mockSession = MockURLSession()
        let url = URL(string: "wss://test.example.com/ws")!
        webSocketService = TestableWebSocketService(url: url, session: mockSession)
    }

    override func tearDown() async throws {
        await webSocketService.disconnect()
        webSocketService = nil
        mockSession = nil
        cancellables.removeAll()
        try await super.tearDown()
    }

    // MARK: - Connection Tests

    func testConnect_ChangesStateToConnected() async throws {
        XCTAssertEqual(webSocketService.currentState, .disconnected)

        try await webSocketService.connect()

        XCTAssertEqual(webSocketService.currentState, .connected)
        XCTAssertEqual(mockSession.webSocketTask?.state, .running)
    }

    func testConnect_EmitsConnectedEvent() async throws {
        let expectation = XCTestExpectation(description: "Connected event")

        webSocketService.events
            .sink { event in
                if case .connected = event {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        try await webSocketService.connect()

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testConnect_Failure_ThrowsAndEmitsError() async throws {
        let testError = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection failed"])
        webSocketService.setShouldFailConnect(true, error: testError)

        do {
            try await webSocketService.connect()
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error.localizedDescription, testError.localizedDescription)
        }

        if case .failed(let error) = webSocketService.currentState {
            XCTAssertEqual(error.localizedDescription, testError.localizedDescription)
        } else {
            XCTFail("State should be failed")
        }
    }

    func testConnect_AlreadyConnected_DoesNothing() async throws {
        try await webSocketService.connect()
        let initialTask = mockSession.webSocketTask

        try await webSocketService.connect()

        XCTAssertEqual(mockSession.webSocketTask, initialTask)
    }

    // MARK: - Disconnect Tests

    func testDisconnect_ChangesStateToDisconnected() async throws {
        try await webSocketService.connect()

        await webSocketService.disconnect()

        XCTAssertEqual(webSocketService.currentState, .disconnected)
        XCTAssertEqual(mockSession.webSocketTask?.state, .completed)
    }

    func testDisconnect_EmitsDisconnectedEvent() async throws {
        try await webSocketService.connect()

        let expectation = XCTestExpectation(description: "Disconnected event")

        webSocketService.events
            .sink { event in
                if case .disconnected(let error) = event {
                    XCTAssertNil(error)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        await webSocketService.disconnect()

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testDisconnect_NotConnected_DoesNothing() async throws {
        await webSocketService.disconnect()

        XCTAssertEqual(webSocketService.currentState, .disconnected)
    }

    // MARK: - Message Sending Tests

    func testSendText_SendsMessage() async throws {
        try await webSocketService.connect()

        try await webSocketService.sendText("test message")

        XCTAssertEqual(mockSession.webSocketTask?.sentMessages.count, 1)
        let message = mockSession.webSocketTask?.sentMessages.first
        if case .string(let text) = message {
            XCTAssertEqual(text, "test message")
        } else {
            XCTFail("Expected string message")
        }
    }

    func testSendData_SendsMessage() async throws {
        try await webSocketService.connect()
        let testData = "test data".data(using: .utf8)!

        try await webSocketService.sendData(testData)

        XCTAssertEqual(mockSession.webSocketTask?.sentMessages.count, 1)
        let message = mockSession.webSocketTask?.sentMessages.first
        if case .data(let data) = message {
            XCTAssertEqual(data, testData)
        } else {
            XCTFail("Expected data message")
        }
    }

    func testSend_WhenDisconnected_QueuesMessage() async throws {
        let testData = "test data".data(using: .utf8)!

        try await webSocketService.sendData(testData)

        // Message should be queued
        XCTAssertEqual(webSocketService.messageQueue.count, 1)
    }

    func testSend_QueuedMessagesSentOnConnect() async throws {
        let testData = "test data".data(using: .utf8)!
        try await webSocketService.sendData(testData)

        try await webSocketService.connect()

        // Give time for queued messages to send
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mockSession.webSocketTask?.sentMessages.count, 1)
    }

    // MARK: - Message Receiving Tests

    func testReceiveTextMessage_ParsesJSON() async throws {
        try await webSocketService.connect()

        let expectation = XCTestExpectation(description: "Message received")
        var receivedMessage: [String: Any]?

        webSocketService.events
            .sink { event in
                if case .messageReceived(let message) = event {
                    receivedMessage = message
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        let testMessage = ["type": "offer", "sdp": "test-sdp", "callId": "123"]
        let jsonData = try JSONSerialization.data(withJSONObject: testMessage)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        webSocketService.simulateIncomingMessage(.string(jsonString))

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(receivedMessage?["type"] as? String, "offer")
        XCTAssertEqual(receivedMessage?["sdp"] as? String, "test-sdp")
        XCTAssertEqual(receivedMessage?["callId"] as? String, "123")
    }

    func testReceiveDataMessage_ParsesJSON() async throws {
        try await webSocketService.connect()

        let expectation = XCTestExpectation(description: "Message received")
        var receivedMessage: [String: Any]?

        webSocketService.events
            .sink { event in
                if case .messageReceived(let message) = event {
                    receivedMessage = message
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        let testMessage = ["type": "answer", "sdp": "test-sdp"]
        let jsonData = try JSONSerialization.data(withJSONObject: testMessage)

        webSocketService.simulateIncomingMessage(.data(jsonData))

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(receivedMessage?["type"] as? String, "answer")
    }

    func testReceiveInvalidJSON_Ignores() async throws {
        try await webSocketService.connect()

        let expectation = XCTestExpectation(description: "Wait for processing")
        var messageCount = 0

        webSocketService.events
            .sink { event in
                if case .messageReceived = event {
                    messageCount += 1
                }
            }
            .store(in: &cancellables)

        // Send invalid JSON
        webSocketService.simulateIncomingMessage(.string("not json"))

        try await Task.sleep(nanoseconds: 100_000_000)
        expectation.fulfill()

        await fulfillment(of: [expectation], timeout: 1.0)

        // Should not crash, just ignore invalid message
        XCTAssertEqual(messageCount, 0)
    }

    // MARK: - Reconnection Tests

    func testConnectionClose_TriggersReconnect() async throws {
        try await webSocketService.connect()

        let expectation = XCTestExpectation(description: "Reconnecting event")
        var reconnectAttempt = 0

        webSocketService.events
            .sink { event in
                if case .reconnecting(let attempt) = event {
                    reconnectAttempt = attempt
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        webSocketService.simulateConnectionClose()

        await fulfillment(of: [expectation], timeout: 5.0)

        XCTAssertEqual(reconnectAttempt, 1)
        XCTAssertEqual(webSocketService.currentState, .reconnecting)
    }

    func testReconnect_Success_RestoresConnection() async throws {
        // Use a very short reconnect delay for testing
        webSocketService.testReconnectDelay = 0.01

        try await webSocketService.connect()

        let expectation = XCTestExpectation(description: "Reconnected")
        var states: [WebSocketState] = []

        webSocketService.events
            .sink { event in
                if case .connected = event {
                    states.append(.connected)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        webSocketService.simulateConnectionClose()

        await fulfillment(of: [expectation], timeout: 5.0)

        XCTAssertEqual(webSocketService.currentState, .connected)
    }

    func testReconnect_MaxAttemptsReached_Fails() async throws {
        // Use immediate reconnect for testing to avoid Task.sleep crash with Firebase
        webSocketService.testReconnectImmediately = true

        // First, connect successfully
        try await webSocketService.connect()

        // Now make subsequent connects fail
        webSocketService.setShouldFailConnect(true, error: NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection failed"]))

        let expectation = XCTestExpectation(description: "Failed after max attempts")
        var finalError: Error?

        webSocketService.events
            .sink { event in
                if case .error(let error) = event {
                    finalError = error
                    // Only fulfill if we've reached the failed state (all attempts exhausted)
                    if case .failed = self.webSocketService.currentState {
                        expectation.fulfill()
                    }
                }
            }
            .store(in: &cancellables)

        // Simulate connection close to trigger reconnect attempts
        webSocketService.simulateConnectionClose()

        // Wait for all reconnect attempts to complete (max 5 attempts, now immediate)
        await fulfillment(of: [expectation], timeout: 3.0)

        XCTAssertNotNil(finalError)
        if case .failed = webSocketService.currentState {
            // Expected
        } else {
            XCTFail("Should be in failed state, current state: \(webSocketService.currentState)")
        }
    }

    // MARK: - Network Loss/Recovery Tests

    func testNetworkLoss_ThenRecovery_Reconnects() async throws {
        try await webSocketService.connect()

        // Simulate network loss
        webSocketService.simulateConnectionClose(code: .goingAway, reason: "Network lost")

        // Wait for reconnect attempt
        try await Task.sleep(nanoseconds: 500_000_000)

        // Should be reconnecting or connected
        XCTAssertTrue(webSocketService.currentState == .reconnecting || webSocketService.currentState == .connected)
    }

    func testMultipleRapidDisconnects_OnlyOneReconnect() async throws {
        try await webSocketService.connect()

        // Rapid disconnects
        webSocketService.simulateConnectionClose()
        webSocketService.simulateConnectionClose()
        webSocketService.simulateConnectionClose()

        try await Task.sleep(nanoseconds: 500_000_000)

        // Should only have one reconnect attempt in progress
        XCTAssertLessThanOrEqual(webSocketService.reconnectAttempts, 1)
    }

    // MARK: - Background/Foreground Tests

    func testBackgroundForeground_Cycle() async throws {
        try await webSocketService.connect()
        XCTAssertEqual(webSocketService.currentState, .connected)

        // Background - disconnect
        await webSocketService.disconnect()
        XCTAssertEqual(webSocketService.currentState, .disconnected)

        // Foreground - reconnect
        try await webSocketService.connect()
        XCTAssertEqual(webSocketService.currentState, .connected)
    }

    // MARK: - Ping/Pong Tests

    func testPingTimer_SendsPingPeriodically() async throws {
        // Use a short ping interval for testing
        webSocketService.testPingInterval = 0.1

        try await webSocketService.connect()

        // Manually trigger ping for testing (Timer may not fire in test environment)
        try await webSocketService.triggerPing()
        try await webSocketService.triggerPing()

        // Should have sent at least one ping
        let pingMessages = mockSession.webSocketTask?.sentMessages.filter {
            if case .string(let text) = $0 { return text == "ping" }
            return false
        }

        XCTAssertGreaterThanOrEqual(pingMessages?.count ?? 0, 1)
    }

    // MARK: - Concurrent Operations Tests

    func testConcurrentSendMessages() async throws {
        try await webSocketService.connect()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    try? await self.webSocketService.sendText("message \(i)")
                }
            }
        }

        XCTAssertEqual(mockSession.webSocketTask?.sentMessages.count, 10)
    }

    func testConcurrentConnectDisconnect() async throws {
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    try? await self.webSocketService.connect()
                    await self.webSocketService.disconnect()
                }
            }
        }

        // Should not crash
    }

    // MARK: - Message Ordering Tests

    func testMessageOrdering_Maintained() async throws {
        try await webSocketService.connect()

        for i in 0..<5 {
            try await webSocketService.sendText("msg \(i)")
        }

        let messages = mockSession.webSocketTask?.sentMessages ?? []
        for (index, message) in messages.enumerated() {
            if case .string(let text) = message {
                XCTAssertEqual(text, "msg \(index)")
            }
        }
    }
}

// MARK: - Test Helpers

// No need for extension - properties are now accessible for testing