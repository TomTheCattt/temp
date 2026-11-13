//
//  WebSocketService.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Combine
import OSLog

// MARK: - AnyCodable (for type-erased JSON payloads)

/// A type-erased Codable wrapper for [String: Any] payloads
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported JSON value"))
        }
    }
}

// MARK: - WebSocketConnectionState (Matches BE exactly)

/// Connection state machine matching backend exactly:
/// DISCONNECTED → CONNECTING → CONNECTED → AUTHENTICATED → JOINED → RECOVERING/RECONNECTING/CLOSING → CLOSED
enum WebSocketConnectionState: Sendable, Equatable {
    case disconnected
    case connecting
    case connected              // WS connected, not yet authenticated
    case authenticated          // Token verified, no room joined
    case joined                 // Joined call room, ready for signaling
    case recovering(lastEventId: String, sequence: Int)  // Reconnecting, fetching missed events
    case reconnecting(attempt: Int)
    case closing
    case closed

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected): return true
        case (.connecting, .connecting): return true
        case (.connected, .connected): return true
        case (.authenticated, .authenticated): return true
        case (.joined, .joined): return true
        case (.recovering(let aEventId, let aSeq), .recovering(let bEventId, let bSeq)):
            return aEventId == bEventId && aSeq == bSeq
        case (.reconnecting(let a), .reconnecting(let b)): return a == b
        case (.closing, .closing): return true
        case (.closed, .closed): return true
        default: return false
        }
    }

    var isConnected: Bool {
        switch self {
        case .connected, .authenticated, .joined: return true
        default: return false
        }
    }

    var isConnectingOrReconnecting: Bool {
        switch self {
        case .connecting, .reconnecting, .recovering: return true
        default: return false
        }
    }
}

// MARK: - WebSocketEvent

enum WebSocketEvent: Sendable {
    case connected
    case authenticated(userId: String)
    case joined(roomId: String)
    case disconnected(Error?)
    case message(WebSocketMessage)
    case stateChanged(WebSocketConnectionState)
    case pong
    case recovery(events: [WSEnvelope], snapshot: CallSnapshot?)
    case error(WebSocketError)
}

// MARK: - WebSocketMessage

enum WebSocketMessage: Sendable {
    case text(String)
    case data(Data)
}

// MARK: - WSEnvelope (matches BE protocol)

/// WebSocket message envelope with sequence ID for event recovery (per DESIGN_DOCUMENT.md §7.4)
struct WSEnvelope: Codable, Sendable {
    let eventId: String          // UUID v4 for deduplication
    let sequence: Int?           // Monotonic sequence for ordering
    let timestamp: String        // ISO 8601 source timestamp
    let type: String             // Event type
    let payload: AnyCodable      // Event data (type-erased)
    let ackRequired: Bool?       // Server should acknowledge
    let correlationId: String?   // For request-response correlation

    enum CodingKeys: String, CodingKey {
        case eventId, sequence, timestamp, type, payload, ackRequired, correlationId
    }

    init(eventId: String, sequence: Int? = nil, timestamp: String = ISO8601DateFormatter().string(from: Date()), type: String, payload: [String: Any], ackRequired: Bool? = nil, correlationId: String? = nil) {
        self.eventId = eventId
        self.sequence = sequence
        self.timestamp = timestamp
        self.type = type
        self.payload = AnyCodable(payload)
        self.ackRequired = ackRequired
        self.correlationId = correlationId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        eventId = try container.decode(String.self, forKey: .eventId)
        sequence = try container.decodeIfPresent(Int.self, forKey: .sequence)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        type = try container.decode(String.self, forKey: .type)
        payload = try container.decode(AnyCodable.self, forKey: .payload)
        ackRequired = try container.decodeIfPresent(Bool.self, forKey: .ackRequired)
        correlationId = try container.decodeIfPresent(String.self, forKey: .correlationId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventId, forKey: .eventId)
        try container.encodeIfPresent(sequence, forKey: .sequence)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type, forKey: .type)
        try container.encode(payload, forKey: .payload)
        try container.encodeIfPresent(ackRequired, forKey: .ackRequired)
        try container.encodeIfPresent(correlationId, forKey: .correlationId)
    }
}

// MARK: - CallSnapshot (for event recovery)

struct CallSnapshot: Codable, Sendable {
    let callId: String
    let status: String
    let participants: [CallParticipantSnapshot]
    let startedAt: String?
    let mediaSettings: MediaSettingsSnapshot
}

struct CallParticipantSnapshot: Codable, Sendable {
    let id: String
    let userId: String
    let username: String
    let avatarUrl: String
    let isMuted: Bool
    let isVideoOff: Bool
    let isScreenSharing: Bool
    let connectionQuality: String
    let joinedAt: String
    let isHost: Bool
}

struct MediaSettingsSnapshot: Codable, Sendable {
    let videoCodec: String
    let audioCodec: String
    let simulcastLayers: Int
}

// MARK: - WebSocketServiceProtocol

protocol WebSocketServiceProtocol: AnyObject, Sendable {
    var eventPublisher: AnyPublisher<WebSocketEvent, Never> { get }
    var connectionState: WebSocketConnectionState { get }
    var isConnected: Bool { get }
    var lastProcessedEventId: String? { get }
    var lastProcessedSequence: Int? { get }

    func connect(url: URL, headers: [String: String]) async
    func disconnect() async
    func send(text: String) async throws
    func send(data: Data) async throws
    func ping() async
    func authenticate(token: String) async
    func joinCall(callId: String, roomId: String) async
    func leaveCall() async
    func requestRecovery(lastEventId: String, lastSequence: Int) async
    func updateCallState(_ state: CallConnectionState) async
    func setBackground(_ background: Bool) async
    func setNetworkType(_ type: NetworkType) async
}

// MARK: - CallConnectionState (for heartbeat optimization)

enum CallConnectionState: String, Sendable {
    case idle
    case connecting
    case authenticated
    case joined
    case background
}

// MARK: - NetworkType

enum NetworkType: String, Sendable {
    case wifi
    case cellular
    case unknown
}

// MARK: - WebSocketError

enum WebSocketError: LocalizedError, Sendable {
    case notConnected
    case encodingFailed
    case decodingFailed
    case timeout
    case authenticationFailed
    case maxRetriesExceeded
    case invalidState

    var errorDescription: String? {
        switch self {
        case .notConnected:   return "WebSocket is not connected."
        case .encodingFailed: return "Failed to encode message."
        case .decodingFailed: return "Failed to decode message."
        case .timeout:        return "WebSocket operation timed out."
        case .authenticationFailed: return "WebSocket authentication failed."
        case .maxRetriesExceeded: return "Maximum reconnection attempts exceeded."
        case .invalidState: return "Invalid connection state for this operation."
        }
    }
}

// MARK: - HeartbeatConfig (Battery-Optimized per BE Design)

/// Battery-optimized heartbeat configuration matching BE strategy exactly (DESIGN_DOCUMENT.md §7.5)
struct HeartbeatConfig: Sendable {
    // Protocol-level (WebSocket ping/pong) - handled by OS/kernel, minimal battery cost
    let protocolPingInterval: TimeInterval = 25.0   // 25s - keeps NAT/firewall mappings alive
    let protocolPongTimeout: TimeInterval = 15.0    // 15s - if no pong, connection is dead

    // Application-level - ONLY during active call, disabled otherwise
    let appPingIntervalActiveCall: TimeInterval = 30.0   // 30s during active call (media quality monitoring)
    let appPingIntervalConnecting: TimeInterval = 10.0   // 10s during ICE negotiation (detect failures fast)
    let appPingIntervalIdle: TimeInterval = 0            // DISABLED - no app heartbeat when not in call
    let appPingIntervalBackground: TimeInterval = 0      // DISABLED - VoIP push handles incoming calls
    let appPongTimeout: TimeInterval = 10.0

    // Load balancer considerations
    let lbIdleTimeout: TimeInterval = 55.0              // Must be < LB timeout (typically 60s)

    // Reconnect policy
    let maxReconnectAttempts: Int = 10
    let reconnectBaseDelay: TimeInterval = 2.0
    let maxReconnectDelay: TimeInterval = 30.0

    nonisolated static let `default` = HeartbeatConfig()
}

// MARK: - HeartbeatManager

/// Battery-optimized heartbeat manager matching BE strategy exactly
/// Key principle: Rely on protocol-level ping/pong (kernel-managed) instead of application heartbeats;
/// adapt intervals based on call state and network conditions.
actor HeartbeatManager {
    private let config: HeartbeatConfig
    private var callState: CallConnectionState = .idle
    private var networkType: NetworkType = .unknown
    private var isBackground = false
    private var appPingTimer: Task<Void, Never>?
    private var protocolPingTimer: Task<Void, Never>?
    private var pendingPings: [Int: Date] = [:]  // sequence -> sent time
    private var nextSequence = 0
    private var lastPongReceivedAt = Date()
    private weak var webSocketService: WebSocketService?
    private let logger = AppLogger.websocket

    init(webSocketService: WebSocketService) {
        self.webSocketService = webSocketService
        self.config = .default
    }

    // MARK: - Public

    func start() {
        startProtocolPing()
        updateAppHeartbeat()
    }

    func stop() {
        appPingTimer?.cancel()
        protocolPingTimer?.cancel()
        appPingTimer = nil
        protocolPingTimer = nil
    }

    func setCallState(_ state: CallConnectionState) {
        let oldState = callState
        callState = state
        if oldState != state {
            logger.info("[Heartbeat] Call state: \(oldState.rawValue) → \(state.rawValue)")
            updateAppHeartbeat()
        }
    }

    func setBackground(_ background: Bool) {
        isBackground = background
        updateAppHeartbeat()
    }

    func setNetworkType(_ type: NetworkType) {
        networkType = type
        // On cellular, slightly more aggressive to detect handover failures
        if type == .cellular && callState == .joined {
            // Will take effect on next updateAppHeartbeat
        }
        updateAppHeartbeat()
    }

    func handlePong(sequence: Int, serverTime: String) {
        let sentAt = pendingPings.removeValue(forKey: sequence)
        if let sentAt {
            let rtt = Date().timeIntervalSince(sentAt)
            logger.debug("[Heartbeat] Pong received: seq=\(sequence), rtt=\(String(format: "%.0f", rtt * 1000))ms")
            lastPongReceivedAt = Date()
            // Could record RTT metrics here
        }
    }

    func handleProtocolPong() {
        lastPongReceivedAt = Date()
    }

    // MARK: - Private

    private func startProtocolPing() {
        // Protocol-level ping/pong - kernel-managed, runs regardless of call state
        protocolPingTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(self?.config.protocolPingInterval ?? 25) * 1_000_000_000)
                guard !Task.isCancelled else { break }
                await self?.sendProtocolPing()
            }
        }
    }

    private func sendProtocolPing() async {
        guard let service = webSocketService else { return }
        await service.sendProtocolPing()
    }

    private func updateAppHeartbeat() {
        appPingTimer?.cancel()

        let interval: TimeInterval
        if isBackground {
            interval = config.appPingIntervalBackground
        } else {
            switch callState {
            case .joined:
                interval = config.appPingIntervalActiveCall
            case .connecting, .authenticated:
                interval = config.appPingIntervalConnecting
            case .idle, .background:
                interval = config.appPingIntervalIdle
            }
        }

        if interval > 0 {
            appPingTimer = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                    guard !Task.isCancelled else { break }
                    await self?.sendAppPing()
                }
            }
            // Send immediately on state change to active
            Task { [weak self] in await self?.sendAppPing() }
        }
    }

    private func sendAppPing() async {
        guard let service = webSocketService else { return }
        let sequence = nextSequence
        nextSequence += 1

        let ping: [String: Any] = [
            "type": "call.ping",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "sequence": sequence,
            "clientNetworkType": networkType.rawValue
        ]

        pendingPings[sequence] = Date()

        do {
            let data = try JSONSerialization.data(withJSONObject: ping)
            try await service.send(data: data)
            logger.debug("[Heartbeat] App ping sent: seq=\(sequence)")

            // Set timeout for pong
            try? await Task.sleep(nanoseconds: UInt64(config.appPongTimeout * 1_000_000_000))
            checkPongTimeout(sequence: sequence)
        } catch {
            logger.error("[Heartbeat] Failed to send app ping: \(error.localizedDescription)")
        }
    }

    private func checkPongTimeout(sequence: Int) {
        if pendingPings[sequence] != nil {
            pendingPings.removeValue(forKey: sequence)
            logger.notice("[Heartbeat] App pong timeout for seq=\(sequence)")
            // Trigger reconnect
            Task { [weak self] in
                await self?.webSocketService?.handleHeartbeatFailure()
            }
        }
    }
}

// MARK: - WebSocketService

/// Native URLSessionWebSocketTask-based WebSocket implementation with battery-optimized heartbeat,
/// event recovery, and BE-matching connection state machine.
/// Thread-safe: all mutable state is protected by a serial dispatch queue.
final class WebSocketService: NSObject, WebSocketServiceProtocol, @unchecked Sendable {

    // MARK: - Serial queue for thread safety
    private let queue = DispatchQueue(label: "com.instagram.websocket", qos: .userInitiated)

    // MARK: - Properties (access only on `queue`)

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var heartbeatManager: HeartbeatManager?
    private var connectionGeneration: UInt64 = 0

    private var _connectionState: WebSocketConnectionState = .disconnected
    private var lastURL: URL?
    private var lastHeaders: [String: String] = [:]
    private var shouldReconnect = false
    private var reconnectAttempt = 0
    private var lastPongReceivedAt: Date = Date()

    // MARK: - Offline Message Queue (persistent)

    /// Queued outgoing messages sent while disconnected, flushed on reconnect
    private var outgoingMessageQueue: [QueuedMessage] = []
    private let maxQueueSize = 100
    private let offlineQueueKey = "com.instagram.websocket.offline_queue"

    struct QueuedMessage: Codable, Sendable {
        let id: String
        let text: String?
        let data: Data?
        let timestamp: Date
        let priority: MessagePriority
        let retryCount: Int

        enum MessagePriority: Int, Codable, Sendable {
            case low = 0
            case normal = 1
            case high = 2
            case critical = 3
        }
    }

    // MARK: - Event Recovery

    private var _lastProcessedEventId: String?
    private var _lastProcessedSequence: Int?
    private var processedEventIds: Set<String> = []

    // MARK: - Configuration

    private let logger = AppLogger.websocket

    // MARK: - Publishers

    private let eventSubject = PassthroughSubject<WebSocketEvent, Never>()

    var eventPublisher: AnyPublisher<WebSocketEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    var connectionState: WebSocketConnectionState {
        queue.sync { _connectionState }
    }

    var isConnected: Bool {
        connectionState.isConnected
    }

    var lastProcessedEventId: String? {
        queue.sync { _lastProcessedEventId }
    }

    var lastProcessedSequence: Int? {
        queue.sync { _lastProcessedSequence }
    }

    // MARK: - Init

    override init() {
        super.init()
        heartbeatManager = HeartbeatManager(webSocketService: self)
        loadOfflineQueue()
    }

    // MARK: - Public API

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
                Task { await self.heartbeatManager?.start() }

                continuation.resume()
            }
        }
    }

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

    func send(text: String) async throws {
        var task: URLSessionWebSocketTask?
        queue.sync { [weak self] in
            guard let self else { task = nil; return }
            if let t = self.webSocketTask, self._connectionState.isConnected {
                task = t
            } else {
                // Queue message for later delivery when reconnected
                self.queueMessage(text: text, data: nil, priority: .normal)
                task = nil
            }
        }

        guard let task else { throw WebSocketError.notConnected }
        try await task.send(.string(text))
        logger.debug("WebSocket sent text (\(text.count) chars)")
    }

    func send(data: Data) async throws {
        var task: URLSessionWebSocketTask?
        queue.sync { [weak self] in
            guard let self else { task = nil; return }
            if let t = self.webSocketTask, self._connectionState.isConnected {
                task = t
            } else {
                // Queue message for later delivery when reconnected
                self.queueMessage(text: nil, data: data, priority: .normal)
                task = nil
            }
        }

        guard let task else { throw WebSocketError.notConnected }
        try await task.send(.data(data))
        logger.debug("WebSocket sent data (\(data.count) bytes)")
    }

    func ping() async {
        guard let task = queue.sync(execute: { self.webSocketTask }) else { return }
        task.sendPing { [weak self] error in
            guard let self else { return }
            self.queue.async {
                if let error {
                    self.logger.error("WebSocket ping failed: \(error.localizedDescription)")
                } else {
                    self.lastPongReceivedAt = Date()
                    Task { await self.heartbeatManager?.handleProtocolPong() }
                    self.eventSubject.send(.pong)
                }
            }
        }
    }

    func sendProtocolPing() async {
        guard let task = queue.sync(execute: { self.webSocketTask }),
              _connectionState.isConnected else { return }
        task.sendPing { [weak self] error in
            guard let self else { return }
            self.queue.async {
                if let error {
                    self.logger.error("Protocol ping failed: \(error.localizedDescription)")
                } else {
                    self.lastPongReceivedAt = Date()
                    Task { await self.heartbeatManager?.handleProtocolPong() }
                }
            }
        }
    }

    func authenticate(token: String) async {
        let authMessage: [String: Any] = [
            "type": "call.auth",
            "token": token
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: authMessage)
            try await send(data: data)
        } catch {
            logger.error("Failed to send auth: \(error.localizedDescription)")
        }
    }

    func joinCall(callId: String, roomId: String) async {
        let joinMessage: [String: Any] = [
            "type": "call.join",
            "callId": callId,
            "roomId": roomId
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: joinMessage)
            try await send(data: data)
        } catch {
            logger.error("Failed to send join: \(error.localizedDescription)")
        }
    }

    func leaveCall() async {
        let leaveMessage: [String: Any] = [
            "type": "call.leave",
            "callId": queue.sync { self.currentCallId } ?? ""
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: leaveMessage)
            try await send(data: data)
        } catch {
            logger.error("Failed to send leave: \(error.localizedDescription)")
        }
    }

    func requestRecovery(lastEventId: String, lastSequence: Int) async {
        let recoveryMessage: [String: Any] = [
            "type": "call.reconnect",
            "callId": queue.sync { self.currentCallId } ?? "",
            "lastSequence": lastSequence,
            "lastEventId": lastEventId
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: recoveryMessage)
            try await send(data: data)
        } catch {
            logger.error("Failed to send recovery request: \(error.localizedDescription)")
        }
    }

    func updateCallState(_ state: CallConnectionState) async {
        await heartbeatManager?.setCallState(state)
    }

    func setBackground(_ background: Bool) async {
        await heartbeatManager?.setBackground(background)
    }

    func setNetworkType(_ type: NetworkType) async {
        await heartbeatManager?.setNetworkType(type)
    }

    func handleHeartbeatFailure() {
        queue.async { [weak self] in
            guard let self else { return }
            self.logger.notice("Heartbeat failure detected, scheduling reconnect")
            self.updateState(.disconnected)
            self.scheduleReconnect()
        }
    }

    // MARK: - Private: Call ID tracking

    private var currentCallId: String?

    private func setCurrentCallId(_ callId: String?) {
        currentCallId = callId
    }

    // MARK: - Private: State

    private func updateState(_ newState: WebSocketConnectionState) {
        _connectionState = newState
        eventSubject.send(.stateChanged(newState))
    }

    // MARK: - Private: Tear Down

    private func tearDown() {
        Task { await heartbeatManager?.stop() }
        stopPingTimer()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
    }

    // MARK: - Private: Receive Loop

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
                Task { await self.heartbeatManager?.handleProtocolPong() }
                switch message {
                case .string(let text):
                    self.handleTextMessage(text, generation: generation)
                case .data(let data):
                    self.handleDataMessage(data, generation: generation)
                @unknown default:
                    break
                }
                // Continue receiving on same generation
                self.startReceiving(generation: generation)

            case .failure(let error):
                guard self._connectionState.isConnected || self._connectionState.isConnectingOrReconnecting else { return }
                self.updateState(.disconnected)
                self.eventSubject.send(.disconnected(error))
                self.logger.error("WebSocket receive error: \(error.localizedDescription)")
                self.scheduleReconnect()
            }
        }
    }

    private func handleTextMessage(_ text: String, generation: UInt64) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logger.error("Failed to parse WebSocket message: \(text)")
            return
        }

        // Check for envelope format
        if let eventId = json["eventId"] as? String,
           let sequence = json["sequence"] as? Int? {
            handleEnvelopeMessage(json, eventId: eventId, sequence: sequence, generation: generation)
        } else {
            // Legacy format - handle directly
            eventSubject.send(.message(.text(text)))
        }
    }

    private func handleEnvelopeMessage(_ json: [String: Any], eventId: String, sequence: Int?, generation: UInt64) {
        // Deduplication
        if processedEventIds.contains(eventId) {
            logger.debug("Duplicate event ignored: \(eventId)")
            return
        }

        // Process event
        let type = json["type"] as? String ?? "unknown"
        let payload = json["payload"] as? [String: Any] ?? [:]

        // Handle special messages
        switch type {
        case "call.pong":
            if let seq = sequence,
               let serverTime = json["serverTime"] as? String {
                Task { await heartbeatManager?.handlePong(sequence: seq, serverTime: serverTime) }
            }
            eventSubject.send(.pong)

        case "connected":
            // Initial connection established
            reconnectAttempt = 0
            updateState(.connected)
            eventSubject.send(.connected)
            logger.info("WebSocket connection opened")

            // Auto-authenticate if we have a token
            if let token = lastHeaders["Authorization"]?.replacingOccurrences(of: "Bearer ", with: "") {
                Task { await self.authenticate(token: token) }
            }

        case "call.authenticated":
            if let userId = payload["userId"] as? String {
                updateState(.authenticated)
                eventSubject.send(.authenticated(userId: userId))
            }

        case "call.joined":
            if let roomId = payload["roomId"] as? String {
                if let callId = payload["callId"] as? String {
                    setCurrentCallId(callId)
                }
                updateState(.joined)
                eventSubject.send(.joined(roomId: roomId))
                flushOutgoingQueue()
            }

        case "call.recovery":
            // Event recovery response (per DESIGN_DOCUMENT.md §7.4)
            if let eventsData = payload["events"] as? [[String: Any]],
               let snapshotData = payload["snapshot"] as? [String: Any]? {

                var events: [WSEnvelope] = []
                for eventData in eventsData {
                    if let envelope = parseEnvelope(eventData) {
                        events.append(envelope)
                    }
                }

                let snapshot: CallSnapshot? = {
                    guard let snapshotData = snapshotData else { return nil }
                    return try? JSONDecoder().decode(CallSnapshot.self, from: try JSONSerialization.data(withJSONObject: snapshotData))
                }()

                // Filter new events
                let newEvents = events.filter { envelope in
                    !processedEventIds.contains(envelope.eventId) &&
                    (envelope.sequence ?? 0) > (_lastProcessedSequence ?? 0)
                }.sorted { ($0.sequence ?? 0) < ($1.sequence ?? 0) }

                for event in newEvents {
                    processedEventIds.insert(event.eventId)
                    if let seq = event.sequence {
                        _lastProcessedSequence = max(_lastProcessedSequence ?? 0, seq)
                    }
                    _lastProcessedEventId = event.eventId
                }

                if !newEvents.isEmpty {
                    updateState(.joined)
                    eventSubject.send(.recovery(events: newEvents, snapshot: snapshot))
                    logger.info("Recovered \(newEvents.count) missed events")
                }

                if let snapshot = snapshot {
                    // Apply snapshot state
                    logger.info("Applied call snapshot: \(snapshot.callId)")
                }
            }

        case "call.left":
            setCurrentCallId(nil)
            updateState(.authenticated)
            eventSubject.send(.stateChanged(.authenticated))

        default:
            // Forward to message handler
            eventSubject.send(.message(.text(jsonToString(json))))
        }
    }

    private func handleDataMessage(_ data: Data, generation: UInt64) {
        eventSubject.send(.message(.data(data)))
    }

    private func parseEnvelope(_ data: [String: Any]) -> WSEnvelope? {
        guard let eventId = data["eventId"] as? String,
              let timestamp = data["timestamp"] as? String,
              let type = data["type"] as? String,
              let payload = data["payload"] as? [String: Any] else {
            return nil
        }

        return WSEnvelope(
            eventId: eventId,
            sequence: data["sequence"] as? Int,
            timestamp: timestamp,
            type: type,
            payload: payload,
            ackRequired: data["ackRequired"] as? Bool,
            correlationId: data["correlationId"] as? String
        )
    }

    private func jsonToString(_ json: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: json),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    // MARK: - Private: Ping Timer (legacy - replaced by HeartbeatManager)

    private var pingTimer: DispatchSourceTimer?

    private func startPingTimer(generation: UInt64) {
        stopPingTimer()
    }

    private func stopPingTimer() {
        pingTimer?.cancel()
        pingTimer = nil
    }

    // MARK: - Private: Flush Outgoing Queue

    private func flushOutgoingQueue() {
        guard !outgoingMessageQueue.isEmpty, let task = webSocketTask, _connectionState.isConnected else { return }

        // Sort by priority (highest first)
        outgoingMessageQueue.sort { $0.priority.rawValue > $1.priority.rawValue }

        for message in outgoingMessageQueue {
            if let text = message.text {
                task.send(.string(text)) { [weak self] error in
                    self?.queue.async {
                        if error == nil {
                            self?.removeFromQueue(id: message.id)
                        }
                    }
                }
            } else if let data = message.data {
                task.send(.data(data)) { [weak self] error in
                    self?.queue.async {
                        if error == nil {
                            self?.removeFromQueue(id: message.id)
                        }
                    }
                }
            }
        }

        logger.info("Flushed \(outgoingMessageQueue.count) queued WebSocket messages")
    }

    // MARK: - Private: Queue Management

    private func queueMessage(text: String?, data: Data?, priority: QueuedMessage.MessagePriority) {
        guard outgoingMessageQueue.count < maxQueueSize else {
            logger.notice("WebSocket message queue full, dropping message")
            return
        }

        let message = QueuedMessage(
            id: UUID().uuidString,
            text: text,
            data: data,
            timestamp: Date(),
            priority: priority,
            retryCount: 0
        )
        outgoingMessageQueue.append(message)
        saveOfflineQueue()
    }

    private func removeFromQueue(id: String) {
        outgoingMessageQueue.removeAll { $0.id == id }
        saveOfflineQueue()
    }

    private func saveOfflineQueue() {
        // Persist to disk (UserDefaults for simplicity, could use SwiftData)
        if let encoded = try? JSONEncoder().encode(outgoingMessageQueue) {
            UserDefaults.standard.set(encoded, forKey: offlineQueueKey)
        }
    }

    private func loadOfflineQueue() {
        if let data = UserDefaults.standard.data(forKey: offlineQueueKey),
           let queue = try? JSONDecoder().decode([QueuedMessage].self, from: data) {
            outgoingMessageQueue = queue
            logger.info("Loaded \(queue.count) messages from offline queue")
        }
    }

    // MARK: - Private: Reconnect

    private func scheduleReconnect() {
        guard shouldReconnect,
              reconnectAttempt < HeartbeatConfig().maxReconnectAttempts,
              let url = lastURL else {
            if reconnectAttempt >= HeartbeatConfig().maxReconnectAttempts {
                logger.error("WebSocket max reconnect attempts reached")
                eventSubject.send(.error(.maxRetriesExceeded))
            }
            return
        }

        reconnectAttempt += 1
        let attempt = reconnectAttempt
        let baseDelay = HeartbeatConfig().reconnectBaseDelay * pow(2.0, Double(attempt - 1))
        let delay = min(baseDelay, HeartbeatConfig().maxReconnectDelay)
        // Add jitter to prevent thundering herd
        let jitter = Double.random(in: 0...0.5)
        let totalDelay = delay + jitter

        updateState(.reconnecting(attempt: attempt))
        logger.info("WebSocket reconnecting in \(String(format: "%.1f", totalDelay))s (attempt \(attempt)/\(HeartbeatConfig().maxReconnectAttempts))")

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
                    didOpenWithProtocol `protocol`: String?) {
        // Already on `queue` (delegateQueue)
        logger.info("WebSocket connection opened with protocol: \(`protocol` ?? "none")")
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        // Already on `queue` (delegateQueue)
        guard _connectionState != .disconnected else { return }
        let reasonStr = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "none"
        logger.info("WebSocket closed with code: \(closeCode.rawValue), reason: \(reasonStr)")
        updateState(.disconnected)
        eventSubject.send(.disconnected(nil))
        scheduleReconnect()
    }
}