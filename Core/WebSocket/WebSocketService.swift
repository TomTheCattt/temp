//
//  WebSocketService.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Combine

// MARK: - WebSocketConnectionState

enum WebSocketConnectionState: Sendable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)
}

// MARK: - WebSocketConnectionState + Equatable

extension WebSocketConnectionState: Equatable {
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected): return true
        case (.connecting, .connecting): return true
        case (.connected, .connected): return true
        case (.reconnecting(let a), .reconnecting(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - WebSocketEvent

enum WebSocketEvent: Sendable {
    case connected
    case disconnected(Error?)
    case message(WebSocketMessage)
    case stateChanged(WebSocketConnectionState)
    case pong
}

// MARK: - WebSocketMessage

enum WebSocketMessage: Sendable {
    case text(String)
    case data(Data)
}

// MARK: - WebSocketServiceProtocol

protocol WebSocketServiceProtocol: AnyObject, Sendable {

    /// Stream of WebSocket events.
    var eventPublisher: AnyPublisher<WebSocketEvent, Never> { get }

    /// Current connection state (observable).
    var connectionState: WebSocketConnectionState { get }

    /// Whether the socket is currently connected.
    var isConnected: Bool { get }

    /// Connect to the WebSocket server.
    func connect(url: URL, headers: [String: String]) async

    /// Disconnect from the WebSocket server.
    func disconnect() async

    /// Send a text message.
    func send(text: String) async throws

    /// Send binary data.
    func send(data: Data) async throws

    /// Send a ping to keep the connection alive.
    func ping() async
}

// MARK: - WebSocketService

/// Native URLSessionWebSocketTask-based WebSocket implementation.
/// Thread-safe: all mutable state is protected by a serial dispatch queue.
final class WebSocketService: NSObject, WebSocketServiceProtocol, @unchecked Sendable {

    // MARK: - Serial queue for thread safety

    private let queue = DispatchQueue(label: "com.instagram.websocket", qos: .userInitiated)

    // MARK: - Properties (access only on `queue`)

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var pingTimer: DispatchSourceTimer?

    private var _connectionState: WebSocketConnectionState = .disconnected
    private var lastURL: URL?
    private var lastHeaders: [String: String] = [:]
    private var shouldReconnect = false
    private var reconnectAttempt = 0
    private var connectionGeneration: UInt64 = 0
    private var lastPongReceivedAt: Date = Date()

    // MARK: - Configuration

    private let reconnectMaxAttempts = 5
    private let reconnectBaseDelay: TimeInterval = 2.0
    private let pingInterval: TimeInterval = 25

    // MARK: - Publishers

    private let eventSubject = PassthroughSubject<WebSocketEvent, Never>()
    private let logger = AppLogger.network

    var eventPublisher: AnyPublisher<WebSocketEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    var connectionState: WebSocketConnectionState {
        queue.sync { _connectionState }
    }

    var isConnected: Bool {
        connectionState == .connected
    }

    // MARK: - Connect

    func connect(url: URL, headers: [String: String] = [:]) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { [weak self] in
                guard let self else {
                    continuation.resume()
                    return
                }

                // Tear down existing connection
                self.tearDown()

                self.connectionGeneration &+= 1
                let currentGeneration = self.connectionGeneration
                self.lastPongReceivedAt = Date()
                self.lastURL = url
                self.lastHeaders = headers
                self.shouldReconnect = true
                self.reconnectAttempt = 0
                self.updateState(.connecting)

                // Create session
                let configuration = URLSessionConfiguration.default
                configuration.waitsForConnectivity = true

                let delegateQueue = OperationQueue()
                delegateQueue.underlyingQueue = self.queue

                self.urlSession = URLSession(
                    configuration: configuration,
                    delegate: self,
                    delegateQueue: delegateQueue
                )

                // Create request
                var request = URLRequest(url: url)
                request.timeoutInterval = 30
                headers.forEach { key, value in
                    request.setValue(value, forHTTPHeaderField: key)
                }

                // Create and resume task
                let task = self.urlSession!.webSocketTask(with: request)
                self.webSocketTask = task
                task.resume()

                self.logger.info("WebSocket connecting to: \(url.absoluteString) [generation: \(currentGeneration)]")
                self.startReceiving(generation: currentGeneration)
                self.startPingTimer(generation: currentGeneration)

                continuation.resume()
            }
        }
    }

    // MARK: - Disconnect

    func disconnect() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { [weak self] in
                guard let self else {
                    continuation.resume()
                    return
                }
                self.shouldReconnect = false
                self.tearDown()
                self.updateState(.disconnected)
                self.eventSubject.send(.disconnected(nil))
                self.logger.info("WebSocket disconnected by user")
                continuation.resume()
            }
        }
    }

    // MARK: - Send

    func send(text: String) async throws {
        guard let task = queue.sync(execute: { webSocketTask }),
              isConnected else {
            throw WebSocketError.notConnected
        }
        try await task.send(.string(text))
        logger.debug("WebSocket sent text (\(text.count) chars)")
    }

    func send(data: Data) async throws {
        guard let task = queue.sync(execute: { webSocketTask }),
              isConnected else {
            throw WebSocketError.notConnected
        }
        try await task.send(.data(data))
        logger.debug("WebSocket sent data (\(data.count) bytes)")
    }

    // MARK: - Ping

    func ping() async {
        guard let task = queue.sync(execute: { webSocketTask }) else { return }
        task.sendPing { [weak self] error in
            guard let self else { return }
            self.queue.async {
                if let error {
                    self.logger.error("WebSocket ping failed: \(error.localizedDescription)")
                } else {
                    self.lastPongReceivedAt = Date()
                    self.eventSubject.send(.pong)
                }
            }
        }
    }

    // MARK: - Private: State

    /// Must be called on `queue`.
    private func updateState(_ newState: WebSocketConnectionState) {
        _connectionState = newState
        eventSubject.send(.stateChanged(newState))
    }

    // MARK: - Private: Tear Down

    /// Must be called on `queue`. Cleans up without sending events.
    private func tearDown() {
        stopPingTimer()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
    }

    // MARK: - Private: Receive Loop

    /// Must be called on `queue`. Guarantees exactly one receive loop per connection generation (Cẩm Nang §5.3).
    private func startReceiving(generation: UInt64) {
        guard let task = webSocketTask else { return }

        task.receive { [weak self] result in
            guard let self else { return }

            // Already on `queue` because delegateQueue uses our serial queue
            guard self.connectionGeneration == generation else {
                self.logger.info("Discarding WebSocket receive loop from stale generation \(generation) (current: \(self.connectionGeneration))")
                return
            }

            switch result {
            case .success(let message):
                self.lastPongReceivedAt = Date()
                switch message {
                case .string(let text):
                    self.eventSubject.send(.message(.text(text)))
                case .data(let data):
                    self.eventSubject.send(.message(.data(data)))
                @unknown default:
                    break
                }
                // Continue receiving on same generation
                self.startReceiving(generation: generation)

            case .failure(let error):
                guard self._connectionState == .connected || self._connectionState == .connecting else { return }
                self.updateState(.disconnected)
                self.eventSubject.send(.disconnected(error))
                self.logger.error("WebSocket receive error: \(error.localizedDescription)")
                self.scheduleReconnect()
            }
        }
    }

    // MARK: - Private: Ping Timer

    /// Must be called on `queue`. Includes watchdog timeout detection for half-open sockets (Cẩm Nang §3.3).
    private func startPingTimer(generation: UInt64) {
        stopPingTimer()

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + pingInterval, repeating: pingInterval)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            guard self.connectionGeneration == generation else { return }

            // Watchdog check: If no message or pong received in 2x pingInterval, mark as dead/half-open
            let silenceDuration = Date().timeIntervalSince(self.lastPongReceivedAt)
            if silenceDuration > (self.pingInterval * 2.2) {
                self.logger.notice("WebSocket half-open connection detected (silence for \(String(format: "%.1f", silenceDuration))s); scheduling reconnect")
                self.updateState(.disconnected)
                self.eventSubject.send(.disconnected(WebSocketError.timeout))
                self.tearDown()
                self.scheduleReconnect()
                return
            }

            Task { [weak self] in
                await self?.ping()
            }
        }
        timer.resume()
        pingTimer = timer
    }

    /// Must be called on `queue`.
    private func stopPingTimer() {
        pingTimer?.cancel()
        pingTimer = nil
    }

    // MARK: - Private: Reconnect

    /// Must be called on `queue`.
    private func scheduleReconnect() {
        guard shouldReconnect,
              reconnectAttempt < reconnectMaxAttempts,
              let url = lastURL else {
            if reconnectAttempt >= reconnectMaxAttempts {
                logger.error("WebSocket max reconnect attempts reached")
            }
            return
        }

        reconnectAttempt += 1
        let attempt = reconnectAttempt
        let delay = reconnectBaseDelay * pow(2.0, Double(attempt - 1))
        // Add jitter to prevent thundering herd
        let jitter = Double.random(in: 0...0.5)
        let totalDelay = delay + jitter

        updateState(.reconnecting(attempt: attempt))
        logger.info("WebSocket reconnecting in \(String(format: "%.1f", totalDelay))s (attempt \(attempt)/\(reconnectMaxAttempts))")

        queue.asyncAfter(deadline: .now() + totalDelay) { [weak self] in
            guard let self, self.shouldReconnect else { return }
            let headers = self.lastHeaders

            Task { [weak self] in
                guard let self else { return }
                await self.connect(url: url, headers: headers)
            }
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketService: URLSessionWebSocketDelegate {

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        // Already on `queue` (delegateQueue)
        reconnectAttempt = 0
        updateState(.connected)
        eventSubject.send(.connected)
        logger.info("WebSocket connection opened")
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        // Already on `queue` (delegateQueue)
        guard _connectionState != .disconnected else { return }
        updateState(.disconnected)
        eventSubject.send(.disconnected(nil))
        logger.info("WebSocket closed with code: \(closeCode.rawValue)")
        scheduleReconnect()
    }
}

// MARK: - WebSocketError

enum WebSocketError: LocalizedError {
    case notConnected
    case encodingFailed
    case decodingFailed
    case timeout

    var errorDescription: String? {
        switch self {
        case .notConnected:   return "WebSocket is not connected."
        case .encodingFailed: return "Failed to encode message."
        case .decodingFailed: return "Failed to decode message."
        case .timeout:        return "WebSocket operation timed out."
        }
    }
}
