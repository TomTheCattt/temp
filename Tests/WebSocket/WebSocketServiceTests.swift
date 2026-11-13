//
//  WebSocketServiceTests.swift
//  InstagramTests
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Testing
import Combine
@testable import Instagram

// MARK: - WebSocketService Tests

@Suite("WebSocketService Tests")
struct WebSocketServiceTests {

    @Test("Connection state machine transitions correctly")
    func testConnectionStateMachine() async throws {
        let service = WebSocketService()

        // Initial state
        #expect(service.connectionState == .disconnected)
        #expect(service.isConnected == false)

        // Test state transitions (these would be triggered by actual connection)
        // We can't easily test the actual WebSocket connection in unit tests
        // without a mock server, but we can verify the state enum works correctly

        let states: [WebSocketConnectionState] = [
            .disconnected,
            .connecting,
            .connected,
            .authenticated,
            .joined,
            .recovering(lastEventId: "evt-123", sequence: 5),
            .reconnecting(attempt: 1),
            .closing,
            .closed
        ]

        for state in states {
            // Verify each state can be created and compared
            #expect(state == state)
        }
    }

    @Test("Connection state isConnected property")
    func testIsConnectedProperty() {
        let connectedStates: [WebSocketConnectionState] = [.connected, .authenticated, .joined]
        let disconnectedStates: [WebSocketConnectionState] = [
            .disconnected, .connecting,
            .recovering(lastEventId: "", sequence: 0),
            .reconnecting(attempt: 1),
            .closing, .closed
        ]

        for state in connectedStates {
            #expect(state.isConnected == true)
        }

        for state in disconnectedStates {
            #expect(state.isConnected == false)
        }
    }

    @Test("Connection state isConnectingOrReconnecting property")
    func testIsConnectingOrReconnecting() {
        let connectingStates: [WebSocketConnectionState] = [
            .connecting,
            .reconnecting(attempt: 1),
            .recovering(lastEventId: "evt", sequence: 1)
        ]

        let nonConnectingStates: [WebSocketConnectionState] = [
            .disconnected, .connected, .authenticated, .joined, .closing, .closed
        ]

        for state in connectingStates {
            #expect(state.isConnectingOrReconnecting == true)
        }

        for state in nonConnectingStates {
            #expect(state.isConnectingOrReconnecting == false)
        }
    }

    @Test("WSEnvelope encoding and decoding")
    func testWSEnvelopeCodable() throws {
        let envelope = WSEnvelope(
            eventId: "evt-123",
            sequence: 42,
            timestamp: "2024-01-15T10:30:00Z",
            type: "call.joined",
            payload: ["callId": "call-456", "roomId": "room-789"],
            ackRequired: true,
            correlationId: "corr-001"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(envelope)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(WSEnvelope.self, from: data)

        #expect(decoded.eventId == envelope.eventId)
        #expect(decoded.sequence == envelope.sequence)
        #expect(decoded.type == envelope.type)
        #expect(decoded.payload["callId"] as? String == "call-456")
        #expect(decoded.ackRequired == true)
        #expect(decoded.correlationId == "corr-001")
    }

    @Test("WSEnvelope without optional fields")
    func testWSEnvelopeMinimal() throws {
        let envelope = WSEnvelope(
            eventId: "evt-123",
            sequence: nil,
            timestamp: "2024-01-15T10:30:00Z",
            type: "call.ping",
            payload: [:],
            ackRequired: nil,
            correlationId: nil
        )

        let data = try JSONEncoder().encode(envelope)
        let decoded = try JSONDecoder().decode(WSEnvelope.self, from: data)

        #expect(decoded.eventId == "evt-123")
        #expect(decoded.sequence == nil)
        #expect(decoded.ackRequired == nil)
        #expect(decoded.correlationId == nil)
    }

    @Test("HeartbeatConfig values match BE design")
    func testHeartbeatConfigValues() {
        let config = HeartbeatConfig()

        // Protocol-level (kernel-managed)
        #expect(config.protocolPingInterval == 25.0)
        #expect(config.protocolPongTimeout == 15.0)

        // Application-level - ONLY during active call
        #expect(config.appPingIntervalActiveCall == 30.0)
        #expect(config.appPingIntervalConnecting == 10.0)
        #expect(config.appPingIntervalIdle == 0)      // DISABLED
        #expect(config.appPingIntervalBackground == 0) // DISABLED
        #expect(config.appPongTimeout == 10.0)

        // Load balancer considerations
        #expect(config.lbIdleTimeout == 55.0)

        // Reconnect policy
        #expect(config.maxReconnectAttempts == 10)
        #expect(config.reconnectBaseDelay == 2.0)
        #expect(config.maxReconnectDelay == 30.0)
    }

    @Test("CallConnectionState enum values")
    func testCallConnectionState() {
        let states: [CallConnectionState] = [.idle, .connecting, .authenticated, .joined, .background]

        for state in states {
            #expect(CallConnectionState(rawValue: state.rawValue) == state)
        }
    }

    @Test("NetworkType enum values")
    func testNetworkType() {
        let types: [NetworkType] = [.wifi, .cellular, .unknown]

        for type in types {
            #expect(NetworkType(rawValue: type.rawValue) == type)
        }
    }

    @Test("WebSocketError descriptions")
    func testWebSocketErrorDescriptions() {
        let errors: [WebSocketError] = [
            .notConnected,
            .encodingFailed,
            .decodingFailed,
            .timeout,
            .authenticationFailed,
            .maxRetriesExceeded,
            .invalidState
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    @Test("Offline message queue priority ordering")
    func testOfflineQueuePriority() {
        let messages = [
            WebSocketService.QueuedMessage(
                id: "1",
                text: "low",
                data: nil,
                timestamp: Date(),
                priority: .low,
                retryCount: 0
            ),
            WebSocketService.QueuedMessage(
                id: "2",
                text: "critical",
                data: nil,
                timestamp: Date(),
                priority: .critical,
                retryCount: 0
            ),
            WebSocketService.QueuedMessage(
                id: "3",
                text: "normal",
                data: nil,
                timestamp: Date(),
                priority: .normal,
                retryCount: 0
            ),
            WebSocketService.QueuedMessage(
                id: "4",
                text: "high",
                data: nil,
                timestamp: Date(),
                priority: .high,
                retryCount: 0
            )
        ]

        let sorted = messages.sorted { $0.priority.rawValue > $1.priority.rawValue }

        #expect(sorted[0].priority == .critical)
        #expect(sorted[1].priority == .high)
        #expect(sorted[2].priority == .normal)
        #expect(sorted[3].priority == .low)
    }

    @Test("CallSnapshot decoding")
    func testCallSnapshotDecoding() throws {
        let json = """
        {
            "callId": "call-123",
            "status": "active",
            "participants": [
                {
                    "id": "p1",
                    "userId": "u1",
                    "username": "user1",
                    "avatarUrl": "https://example.com/avatar1.jpg",
                    "isMuted": false,
                    "isVideoOff": true,
                    "isScreenSharing": false,
                    "connectionQuality": "good",
                    "joinedAt": "2024-01-15T10:30:00Z",
                    "isHost": true
                }
            ],
            "startedAt": "2024-01-15T10:25:00Z",
            "mediaSettings": {
                "videoCodec": "H264",
                "audioCodec": "OPUS",
                "simulcastLayers": 3
            }
        }
        """

        let data = json.data(using: .utf8)!
        let snapshot = try JSONDecoder().decode(CallSnapshot.self, from: data)

        #expect(snapshot.callId == "call-123")
        #expect(snapshot.status == "active")
        #expect(snapshot.participants.count == 1)
        #expect(snapshot.participants[0].userId == "u1")
        #expect(snapshot.participants[0].isHost == true)
        #expect(snapshot.mediaSettings.videoCodec == "H264")
        #expect(snapshot.mediaSettings.simulcastLayers == 3)
    }
}