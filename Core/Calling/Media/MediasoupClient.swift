//
//  MediasoupClient.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//
//  Mediasoup SFU client for iOS.
//  Handles transport creation, produce/consume, and SFU signaling.

import Foundation
import Combine
import CoreMedia

#if canImport(WebRTC)
import WebRTC
#endif

// Import proper AppLogger from Core.Logging
// (No import needed - same module)

// MARK: - Mediasoup Types

/// Mediasoup transport options from server.
struct MediasoupTransportOptions: Sendable, Codable {
    let id: String
    let iceParameters: IceParameters
    let iceCandidates: [MediasoupIceCandidate]
    let dtlsParameters: DtlsParameters
    let sctpParameters: SctpParameters?
}

/// ICE parameters from mediasoup.
struct IceParameters: Sendable, Codable {
    let usernameFragment: String
    let password: String
}

/// ICE candidate from mediasoup (renamed to avoid conflict with WebRTC's RTCIceCandidate).
struct MediasoupIceCandidate: Sendable, Codable {
    let foundation: String
    let priority: Int
    let ip: String
    let port: Int
    let type: String
    let `protocol`: String
    let component: Int
    let relatedAddress: String?
    let relatedPort: Int?
    let tcpType: String?
}

/// DTLS parameters from mediasoup.
struct DtlsParameters: Sendable, Codable {
    let role: String // "auto", "client", "server"
    let fingerprints: [DtlsFingerprint]
}

/// DTLS fingerprint.
struct DtlsFingerprint: Sendable, Codable {
    let algorithm: String
    let value: String
}

/// SCTP parameters.
struct SctpParameters: Sendable, Codable {
    let port: Int
    let OS: Int
    let MIS: Int
}

/// Producer options.
struct ProducerOptions: Sendable, Codable {
    let kind: String // "audio" or "video"
    let rtpParameters: RtpParameters
    let encodings: [RtpEncodingParameters]?
    let codecOptions: CodecOptions?
    let appData: [String: String]?
}

/// RTP parameters.
struct RtpParameters: Sendable, Codable {
    let mid: String?
    let codecs: [RtpCodecParameters]
    let headerExtensions: [RtpHeaderExtensionParameters]
    let rtcp: RtcpParameters?
}

/// RTP codec parameters.
struct RtpCodecParameters: Sendable, Codable {
    let mimeType: String
    let payloadType: Int
    let clockRate: Int
    let channels: Int?
    let parameters: [String: String]?
    let rtcpFeedback: [RtcpFeedback]?
}

/// RTP encoding parameters (simulcast).
struct RtpEncodingParameters: Sendable, Codable {
    let rid: String?
    let active: Bool?
    let maxBitrate: Int?
    let maxFramerate: Int?
    let scaleResolutionDownBy: Double?
    let codecPayloadType: Int?
}

/// Codec options.
struct CodecOptions: Sendable, Codable {
    let videoGoogleStartBitrate: Int?
    let videoGoogleMaxBitrate: Int?
    let videoGoogleMinBitrate: Int?
}

/// RTP header extension.
struct RtpHeaderExtensionParameters: Sendable, Codable {
    let uri: String
    let id: Int
    let encrypt: Bool?
    let parameters: [String: String]?
}

/// RTCP parameters.
struct RtcpParameters: Sendable, Codable {
    let cname: String?
    let reducedSize: Bool?
}

/// RTCP feedback.
struct RtcpFeedback: Sendable, Codable {
    let type: String
    let parameter: String?
}

/// Consumer options.
struct ConsumerOptions: Sendable, Codable {
    let producerId: String
    let rtpCapabilities: RtpCapabilities
    let paused: Bool?
    let preferredLayers: [PreferredLayer]?
    let kind: String
    let rtpParameters: RtpParameters
}

/// Preferred layer for consumer.
struct PreferredLayer: Sendable, Codable {
    let spatialLayer: Int
    let temporalLayer: Int?
}

/// RTP capabilities.
struct RtpCapabilities: Sendable, Codable {
    let codecs: [RtpCodecParameters]
    let headerExtensions: [RtpHeaderExtensionParameters]
}

/// Producer info from server.
struct ProducerInfo: Sendable, Codable {
    let id: String
    let kind: String
    let rtpParameters: RtpParameters
    let type: String // "simple", "simulcast", "svc"
    let appData: [String: String]?
}

/// Consumer info from server.
struct ConsumerInfo: Sendable, Codable {
    let id: String
    let producerId: String
    let kind: String
    let rtpParameters: RtpParameters
    let type: String
    let appData: [String: String]?
}

/// Room info.
struct RoomInfo: Sendable, Codable {
    let id: String
    let peers: [PeerInfo]
}

/// Peer info.
struct PeerInfo: Sendable, Codable {
    let id: String
    let producers: [String] // producer IDs
    let consumers: [String] // consumer IDs
}

// MARK: - MediasoupClientProtocol

protocol MediasoupClientProtocol: AnyObject, Sendable {
    var connectionState: MediasoupConnectionState { get }
    var connectionStatePublisher: AnyPublisher<MediasoupConnectionState, Never> { get }

    func connect(roomId: String, peerId: String, rtpCapabilities: RtpCapabilities) async throws
    func disconnect()

    // Transport
    func createSendTransport(options: MediasoupTransportOptions) async throws -> SendTransport
    func createRecvTransport(options: MediasoupTransportOptions) async throws -> RecvTransport

    // Producer
    func produce(transport: SendTransport, options: ProducerOptions) async throws -> Producer
    func closeProducer(_ producer: Producer) async throws

    // Consumer
    func consume(transport: RecvTransport, options: ConsumerOptions) async throws -> Consumer
    func closeConsumer(_ consumer: Consumer) async throws

    // Stats
    func getProducerStats(_ producerId: String) async throws -> ProducerStats
    func getConsumerStats(_ consumerId: String) async throws -> ConsumerStats
}

/// Connection state.
enum MediasoupConnectionState: Sendable, Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case failed(Error)

    static func == (lhs: MediasoupConnectionState, rhs: MediasoupConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected): return true
        case (.connecting, .connecting): return true
        case (.connected, .connected): return true
        case (.reconnecting, .reconnecting): return true
        case (.failed(let lhsErr), .failed(let rhsErr)):
            return lhsErr.localizedDescription == rhsErr.localizedDescription
        default: return false
        }
    }
}

// MARK: - Transport

/// Send transport for producing media.
final class SendTransport: @unchecked Sendable {
    let id: String
    let iceParameters: IceParameters
    let iceCandidates: [MediasoupIceCandidate]
    let dtlsParameters: DtlsParameters
    let sctpParameters: SctpParameters?

    private var dtlsState: DtlsState = .new
    private var iceState: IceState = .new

    enum DtlsState: String, Sendable { case new, connecting, connected, failed, closed }
    enum IceState: String, Sendable { case new, checking, connected, completed, failed, disconnected, closed }

    init(options: MediasoupTransportOptions) {
        self.id = options.id
        self.iceParameters = options.iceParameters
        self.iceCandidates = options.iceCandidates
        self.dtlsParameters = options.dtlsParameters
        self.sctpParameters = options.sctpParameters
    }

    func connect(dtlsParameters: DtlsParameters) async throws {
        // In real implementation, this would call WebRTC setRemoteDescription
        // and start ICE/DTLS negotiation
        self.dtlsState = .connected
    }

    func produce(options: ProducerOptions) async throws -> Producer {
        // In real implementation, this would create an RTCRtpSender
        // and start sending media
        return Producer(id: UUID().uuidString, kind: options.kind, rtpParameters: options.rtpParameters)
    }
}

/// Receive transport for consuming media.
final class RecvTransport: @unchecked Sendable {
    let id: String
    let iceParameters: IceParameters
    let iceCandidates: [MediasoupIceCandidate]
    let dtlsParameters: DtlsParameters
    let sctpParameters: SctpParameters?

    init(options: MediasoupTransportOptions) {
        self.id = options.id
        self.iceParameters = options.iceParameters
        self.iceCandidates = options.iceCandidates
        self.dtlsParameters = options.dtlsParameters
        self.sctpParameters = options.sctpParameters
    }

    func connect(dtlsParameters: DtlsParameters) async throws {
        // In real implementation, this would call WebRTC setRemoteDescription
    }

    func consume(options: ConsumerOptions) async throws -> Consumer {
        // In real implementation, this would create an RTCRtpReceiver
        return Consumer(
            id: UUID().uuidString,
            producerId: options.producerId,
            kind: options.kind,
            rtpParameters: options.rtpParameters
        )
    }
}

// MARK: - Producer / Consumer

final class Producer: @unchecked Sendable, Identifiable {
    let id: String
    let kind: String
    let rtpParameters: RtpParameters
    var isPaused = false

    init(id: String, kind: String, rtpParameters: RtpParameters) {
        self.id = id
        self.kind = kind
        self.rtpParameters = rtpParameters
    }

    func pause() async throws { isPaused = true }
    func resume() async throws { isPaused = false }
    func replaceTrack(_ track: Any?) async throws { /* WebRTC track replacement */ }
    func setEncodingParameters(_ params: [RtpEncodingParameters]) async throws { /* Update simulcast */ }
    func getStats() async throws -> ProducerStats { ProducerStats() }
}

final class Consumer: @unchecked Sendable, Identifiable {
    let id: String
    let producerId: String
    let kind: String
    let rtpParameters: RtpParameters
    var isPaused = false

    init(id: String, producerId: String, kind: String, rtpParameters: RtpParameters) {
        self.id = id
        self.producerId = producerId
        self.kind = kind
        self.rtpParameters = rtpParameters
    }

    func pause() async throws { isPaused = true }
    func resume() async throws { isPaused = false }
    func setPreferredLayers(_ layers: [PreferredLayer]?) async throws { /* Layer selection */ }
    func getStats() async throws -> ConsumerStats { ConsumerStats() }
    func requestKeyFrame() async throws { /* PLI */ }
}

// MARK: - Stats

struct ProducerStats: Sendable, Codable {
    var timestamp: Date = Date()
    var bytesSent: Int64 = 0
    var packetsSent: Int64 = 0
    var bitrate: Double = 0 // bps
    var rtt: Double = 0 // ms
    var packetsLost: Int64 = 0
    var fractionLost: Double = 0
}

struct ConsumerStats: Sendable, Codable {
    var timestamp: Date = Date()
    var bytesReceived: Int64 = 0
    var packetsReceived: Int64 = 0
    var bitrate: Double = 0 // bps
    var rtt: Double = 0 // ms
    var packetsLost: Int64 = 0
    var fractionLost: Double = 0
    var jitter: Double = 0 // ms
    var framesDecoded: Int64 = 0
    var framesDropped: Int64 = 0
}

// MARK: - MediasoupClient (Implementation - WebRTC Dependent)

#if canImport(WebRTC)

/// Mediasoup client implementation using WebRTC and WebSocket signaling.
/// This is a bridge between the iOS WebRTC stack and mediasoup SFU.
@MainActor
final class MediasoupClient: MediasoupClientProtocol, @unchecked Sendable {

    // MARK: - State

    private(set) var connectionState: MediasoupConnectionState = .disconnected
    private let connectionStateSubject = CurrentValueSubject<MediasoupConnectionState, Never>(.disconnected)
    var connectionStatePublisher: AnyPublisher<MediasoupConnectionState, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }

    // WebRTC components
    private var peerConnectionFactory: RTCPeerConnectionFactory?
    private var sendTransportPc: RTCPeerConnection?
    private var recvTransportPc: RTCPeerConnection?

    // Signaling
    private var signalingWebSocket: WebSocket?
    private var roomId: String?
    private var peerId: String?
    private var rtpCapabilities: RtpCapabilities?

    // Active transports/producers/consumers
    private var sendTransport: SendTransport?
    private var recvTransport: RecvTransport?
    private var producers: [String: Producer] = [:]
    private var consumers: [String: Consumer] = [:]

    private let logger = AppLogger.general
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        setupWebRTC()
    }

    private func setupWebRTC() {
        RTCInitializeSSL()
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        peerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: encoderFactory, decoderFactory: decoderFactory)
        logger.info("MediasoupClient: WebRTC initialized")
    }

    // MARK: - Connection

    func connect(roomId: String, peerId: String, rtpCapabilities: RtpCapabilities) async throws {
        guard connectionState != .connecting && connectionState != .connected else { return }

        self.roomId = roomId
        self.peerId = peerId
        self.rtpCapabilities = rtpCapabilities

        updateConnectionState(.connecting)

        // Connect WebSocket signaling
        try await connectSignaling()

        // Send join room request
        try await sendJoinRequest(rtpCapabilities: rtpCapabilities)

        updateConnectionState(.connected)
        logger.info("MediasoupClient: Connected to room \(roomId)")
    }

    func disconnect() {
        // Close all producers/consumers
        for producer in producers.values {
            try? await closeProducer(producer)
        }
        for consumer in consumers.values {
            try? await closeConsumer(consumer)
        }

        // Close transports
        sendTransport = nil
        recvTransport = nil

        // Close peer connections
        sendTransportPc?.close()
        recvTransportPc?.close()
        sendTransportPc = nil
        recvTransportPc = nil

        // Disconnect signaling
        signalingWebSocket?.close()
        signalingWebSocket = nil

        roomId = nil
        peerId = nil

        updateConnectionState(.disconnected)
        logger.info("MediasoupClient: Disconnected")
    }

    // MARK: - Signaling

    private func connectSignaling() async throws {
        // Connect to mediasoup signaling WebSocket
        // URL would be something like: wss://sfu.example.com/mediasoup?roomId=xxx&peerId=xxx
        // This is a placeholder - actual implementation depends on backend
        logger.info("MediasoupClient: Connecting signaling WebSocket")
    }

    private func sendJoinRequest(rtpCapabilities: RtpCapabilities) async throws {
        // Send join request to mediasoup server
        let message = [
            "type": "join",
            "roomId": roomId ?? "",
            "peerId": peerId ?? "",
            "rtpCapabilities": rtpCapabilities
        ] as [String: Any]

        try await sendSignalingMessage(message)
    }

    private func sendSignalingMessage(_ message: [String: Any]) async throws {
        // Send via WebSocket
        guard let ws = signalingWebSocket else { throw MediasoupError.notConnected }

        let data = try JSONSerialization.data(withJSONObject: message)
        try await ws.send(data: data)
    }

    private func handleSignalingMessage(_ data: Data) {
        // Parse and handle incoming signaling messages
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "joined":
            // Room joined, create transports
            handleJoined(json)
        case "newPeer":
            // New peer joined, create consumer for their producers
            handleNewPeer(json)
        case "producerClosed":
            // Peer closed producer, close consumer
            handleProducerClosed(json)
        case "transportConnect":
            // Server requests transport connection (DTLS)
            handleTransportConnect(json)
        case "produce":
            // Server confirms producer created
            handleProduce(json)
        case "consume":
            // Server confirms consumer created
            handleConsume(json)
        case "consumerClosed":
            handleConsumerClosed(json)
        default:
            break
        }
    }

    private func handleJoined(_ json: [String: Any]) {
        // Create send and recv transports
        // This would be triggered by server sending transport options
    }

    private func handleNewPeer(_ json: [String: Any]) {
        // Create consumers for new peer's producers
    }

    private func handleProducerClosed(_ json: [String: Any]) {
        // Close corresponding consumer
    }

    private func handleTransportConnect(_ json: [String: Any]) {
        // Handle DTLS parameters from server
    }

    private func handleProduce(_ json: [String: Any]) {
        // Producer created on server
    }

    private func handleConsume(_ json: [String: Any]) {
        // Consumer created on server
    }

    private func handleConsumerClosed(_ json: [String: Any]) {
        // Consumer closed on server
    }

    // MARK: - Transport

    func createSendTransport(options: MediasoupTransportOptions) async throws -> SendTransport {
        guard let factory = peerConnectionFactory else { throw MediasoupError.webRTCNotInitialized }

        let transport = SendTransport(options: options)

        // Create WebRTC peer connection for send transport
        let config = RTCConfiguration()
        config.iceServers = options.iceCandidates.map { candidate in
            RTCIceServer(
                urlStrings: ["\(candidate.protocol)://\(candidate.ip):\(candidate.port)"],
                username: options.iceParameters.usernameFragment,
                credential: options.iceParameters.password
            )
        }

        sendTransportPc = factory.peerConnection(
            with: config,
            constraints: RTCHardwareConstraints(),
            delegate: MediasoupSendTransportDelegate(transport: transport, client: self)
        )

        // Connect DTLS
        try await transport.connect(dtlsParameters: options.dtlsParameters)

        sendTransport = transport
        return transport
    }

    func createRecvTransport(options: MediasoupTransportOptions) async throws -> RecvTransport {
        guard let factory = peerConnectionFactory else { throw MediasoupError.webRTCNotInitialized }

        let transport = RecvTransport(options: options)

        let config = RTCConfiguration()
        config.iceServers = options.iceCandidates.map { candidate in
            RTCIceServer(
                urlStrings: ["\(candidate.protocol)://\(candidate.ip):\(candidate.port)"],
                username: options.iceParameters.usernameFragment,
                credential: options.iceParameters.password
            )
        }

        recvTransportPc = factory.peerConnection(
            with: config,
            constraints: RTCHardwareConstraints(),
            delegate: MediasoupRecvTransportDelegate(transport: transport, client: self)
        )

        try await transport.connect(dtlsParameters: options.dtlsParameters)

        recvTransport = transport
        return transport
    }

    // MARK: - Producer

    func produce(transport: SendTransport, options: ProducerOptions) async throws -> Producer {
        guard let pc = sendTransportPc else { throw MediasoupError.transportNotReady }

        // Create WebRTC sender
        // This requires adding a track to the peer connection
        // The track comes from our local media pipeline

        let producer = Producer(id: UUID().uuidString, kind: options.kind, rtpParameters: options.rtpParameters)
        producers[producer.id] = producer

        // Send produce request to server
        let message = [
            "type": "produce",
            "transportId": transport.id,
            "kind": options.kind,
            "rtpParameters": options.rtpParameters,
            "encodings": options.encodings ?? [],
            "codecOptions": options.codecOptions ?? [:],
            "appData": options.appData ?? [:]
        ] as [String: Any]

        try await sendSignalingMessage(message)

        return producer
    }

    func closeProducer(_ producer: Producer) async throws {
        producers.removeValue(forKey: producer.id)

        let message = [
            "type": "closeProducer",
            "producerId": producer.id
        ] as [String: Any]

        try await sendSignalingMessage(message)
    }

    // MARK: - Consumer

    func consume(transport: RecvTransport, options: ConsumerOptions) async throws -> Consumer {
        guard let pc = recvTransportPc else { throw MediasoupError.transportNotReady }

        // Create WebRTC receiver
        let consumer = Consumer(
            id: UUID().uuidString,
            producerId: options.producerId,
            kind: options.kind,
            rtpParameters: options.rtpParameters
        )
        consumers[consumer.id] = consumer

        // Send consume request to server
        let message = [
            "type": "consume",
            "transportId": transport.id,
            "producerId": options.producerId,
            "rtpCapabilities": options.rtpCapabilities,
            "paused": options.paused ?? false,
            "preferredLayers": options.preferredLayers ?? []
        ] as [String: Any]

        try await sendSignalingMessage(message)

        return consumer
    }

    func closeConsumer(_ consumer: Consumer) async throws {
        consumers.removeValue(forKey: consumer.id)

        let message = [
            "type": "closeConsumer",
            "consumerId": consumer.id
        ] as [String: Any]

        try await sendSignalingMessage(message)
    }

    // MARK: - Stats

    func getProducerStats(_ producerId: String) async throws -> ProducerStats {
        // Get stats from WebRTC sender
        return ProducerStats()
    }

    func getConsumerStats(_ consumerId: String) async throws -> ConsumerStats {
        // Get stats from WebRTC receiver
        return ConsumerStats()
    }

    // MARK: - Private

    private func updateConnectionState(_ state: MediasoupConnectionState) {
        connectionState = state
        connectionStateSubject.send(state)
    }
}

// MARK: - WebRTC Delegates

private final class MediasoupSendTransportDelegate: NSObject, RTCPeerConnectionDelegate {
    private let transport: SendTransport
    private weak var client: MediasoupClient?

    init(transport: SendTransport, client: MediasoupClient) {
        self.transport = transport
        self.client = client
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        // Send ICE candidate to server
    }
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}

private final class MediasoupRecvTransportDelegate: NSObject, RTCPeerConnectionDelegate {
    private let transport: RecvTransport
    private weak var client: MediasoupClient?

    init(transport: RecvTransport, client: MediasoupClient) {
        self.transport = transport
        self.client = client
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        // Handle incoming stream from SFU
    }
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}

#endif // canImport(WebRTC)

// MARK: - WebSocket Protocol (Placeholder)

protocol WebSocket: AnyObject, Sendable {
    func send(data: Data) async throws
    func close()
}

// MARK: - Errors

enum MediasoupError: LocalizedError {
    case notConnected
    case webRTCNotInitialized
    case webRTCNotAvailable
    case transportNotReady
    case signalingFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConnected: return "Not connected to mediasoup server"
        case .webRTCNotInitialized: return "WebRTC not initialized"
        case .webRTCNotAvailable: return "WebRTC framework not available"
        case .transportNotReady: return "Transport not ready"
        case .signalingFailed(let msg): return "Signaling failed: \(msg)"
        }
    }
}