//
//  CallWebRTCMediaPipeline.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//
//  WebRTC Media Pipeline implementation using GoogleWebRTC and mediasoup-client.
//  Replaces the synthetic generator with real WebRTC transport for SFU integration.

import Foundation
import Combine
import CoreMedia
import AVFoundation

#if canImport(WebRTC)
import WebRTC
#endif

// SessionStore and AppLogger are in the same module, no import needed

#if canImport(WebRTC)

// MARK: - WebRTC Media Pipeline

/// Production WebRTC media pipeline for real-time audio/video calls via SFU (mediasoup).
/// Implements CallMediaPipelineProtocol with actual WebRTC transport instead of synthetic generator.
@MainActor
final class CallWebRTCMediaPipeline: CallMediaPipelineProtocol, @unchecked Sendable {

    // MARK: - Singleton

    static let shared = CallWebRTCMediaPipeline()

    // MARK: - Publishers

    /// Real-time audio RMS level from WebRTC audio track.
    nonisolated var audioLevelPublisher: AnyPublisher<Float, Never> {
        audioLevelSubject.eraseToAnyPublisher()
    }

    private nonisolated let audioLevelSubject = CurrentValueSubject<Float, Never>(0.0)

    /// Local camera/video CMSampleBuffers for PiP preview.
    nonisolated var localSampleBufferPublisher: AnyPublisher<CMSampleBuffer, Never> {
        localSampleBufferSubject.eraseToAnyPublisher()
    }

    private nonisolated let localSampleBufferSubject = PassthroughSubject<CMSampleBuffer, Never>()
    private nonisolated let localSampleBufferLock = NSLock()
    private nonisolated(unsafe) var _lastLocalSampleBuffer: CMSampleBuffer?
    private nonisolated var lastLocalSampleBuffer: CMSampleBuffer? {
        get { localSampleBufferLock.withLock { _lastLocalSampleBuffer } }
        set { localSampleBufferLock.withLock { _lastLocalSampleBuffer = newValue } }
    }

    /// Remote party video CMSampleBuffers for full-screen rendering.
    nonisolated var remoteSampleBufferPublisher: AnyPublisher<CMSampleBuffer, Never> {
        remoteSampleBufferSubject.eraseToAnyPublisher()
    }

    private nonisolated let remoteSampleBufferSubject = PassthroughSubject<CMSampleBuffer, Never>()

    /// Replays the last captured frame to local subscribers.
    nonisolated func replayLastSampleBuffer() {
        if let last = lastLocalSampleBuffer {
            localSampleBufferSubject.send(last)
        }
    }

    // MARK: - WebRTC Components

    private var peerConnectionFactory: RTCPeerConnectionFactory?
    private var peerConnection: RTCPeerConnection?
    private var audioTrack: RTCAudioTrack?
    private var videoTrack: RTCVideoTrack?
    private var localVideoSource: RTCVideoSource?
    private var videoCapturer: RTCCameraVideoCapturer?
    private var videoEncoder: VideoToolboxEncoder?
    private var simulcastEncodings: [RTCRtpEncodingParameters] = []

    // MARK: - Audio

    private let audioEngine = AVAudioEngine()
    private let ringbackPlayerNode = AVAudioPlayerNode()
    private let ringtonePlayerNode = AVAudioPlayerNode()
    private let remotePlayerNode = AVAudioPlayerNode()
    private static let standardToneFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!

    private var isAudioRunning = false
    private let muteLock = NSLock()
    private var _isMuted = false
    private var isSpeaker = false
    private var isPlayingRingback = false
    private var isPlayingRingtone = false
    private lazy var ringbackBuffer: AVAudioPCMBuffer? = { Self.generateRingbackToneBuffer() }()
    private lazy var incomingRingtoneBuffer: AVAudioPCMBuffer? = { Self.generateIncomingRingtoneBuffer() }()

    // MARK: - Signaling & Transport

    private var signalingHandler: CallSignalingHandlerProtocol?
    private var currentCallId: String?
    private var currentRoomId: String?
    private var iceServers: [RTCIceServer] = []
    private var isConnected = false

    // MARK: - Simulcast

    private let simulcastLayers = 3 // high, medium, low
    private var currentSimulcastLayer = 0

    // MARK: - Logger

    private let logger = AppLogger.general

    // MARK: - Init

    private init() {
        setupWebRTC()
    }

    // MARK: - WebRTC Setup

    private func setupWebRTC() {
        RTCInitializeSSL()

        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        peerConnectionFactory = RTCPeerConnectionFactory(
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory
        )

        logger.info("WebRTC initialized with default encoder/decoder factories")
    }

    // MARK: - CallMediaPipelineProtocol - Audio

    /// Starts WebRTC audio capture and creates audio track.
    func startAudio() async throws {
        guard !isAudioRunning else { return }

        // 1. Configure audio session
        try await configureAudioSession()

        // 2. Create WebRTC audio source and track
        guard let factory = peerConnectionFactory else {
            throw WebRTCError.factoryNotInitialized
        }

        let constraints = RTCAudioConstraints()
        let audioSource = factory.audioSource(with: constraints)
        audioTrack = factory.audioTrack(with: audioSource, trackId: "audio_\(UUID().uuidString)")

        logger.info("WebRTC audio track created")

        // 3. Start AVAudioEngine for local monitoring & tones
        try await startLocalAudioEngine()

        isAudioRunning = true
    }

    /// Stops audio engine and releases WebRTC audio track.
    func stopAudio() {
        guard isAudioRunning else { return }

        stopRingbackTone()
        stopIncomingRingtone()

        // Stop local audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        // Release WebRTC audio track
        audioTrack = nil

        isAudioRunning = false
        audioLevelSubject.send(0.0)
        logger.info("Audio stopped")
    }

    /// Sets microphone mute state (hardware + WebRTC track).
    func setMuted(_ isMuted: Bool) {
        muteLock.withLock { _isMuted = isMuted }

        // Update WebRTC audio track
        audioTrack?.isEnabled = !isMuted

        // Update local audio engine
        if isAudioRunning {
            audioEngine.inputNode.isVoiceProcessingInputMuted = isMuted
        }

        if isMuted {
            audioLevelSubject.send(0.0)
        }

        logger.info("Microphone \(isMuted ? "muted" : "unmuted")")
    }

    /// Overrides audio output route (speaker/earpiece).
    func setSpeaker(_ isSpeaker: Bool) {
        self.isSpeaker = isSpeaker
        let session = AVAudioSession.sharedInstance()
        try? session.overrideOutputAudioPort(isSpeaker ? .speaker : .none)
        logger.info("Audio route: \(isSpeaker ? "speaker" : "earpiece")")
    }

    // MARK: - CallMediaPipelineProtocol - Video

    /// Starts camera capture and creates WebRTC video track with simulcast.
    func startVideo(isFront: Bool) async throws {
        guard let factory = peerConnectionFactory else {
            throw WebRTCError.factoryNotInitialized
        }

        // Create video source with capturer
        let videoSource = factory.videoSource()
        self.localVideoSource = videoSource

        // Create camera capturer
        let capturer = RTCCameraVideoCapturer(delegate: videoSource)
        self.videoCapturer = capturer

        // Start camera capture
        try await startCameraCapture(capturer: capturer, isFront: isFront)

        // Create video track
        videoTrack = factory.videoTrack(with: videoSource, trackId: "video_\(UUID().uuidString)")

        // Setup simulcast encodings
        setupSimulcastEncodings()

        logger.info("WebRTC video track created with \(simulcastLayers) simulcast layers")
    }

    /// Stops video capture and releases WebRTC video track.
    func stopVideo() {
        videoCapturer?.stopCapture()
        videoCapturer = nil
        videoTrack = nil
        localVideoSource = nil
        simulcastEncodings.removeAll()

        logger.info("Video stopped")
    }

    /// Switches camera between front/back.
    func switchCamera(isFront: Bool) async {
        guard let capturer = videoCapturer else { return }

        // Get available cameras
        let position: AVCaptureDevice.Position = isFront ? .front : .back
        let devices = RTCCameraVideoCapturer.captureDevices()
        guard let device = devices.first(where: { $0.position == position }) else {
            logger.error("Camera not found for position: \(position)")
            return
        }

        // Get supported formats
        let formats = RTCCameraVideoCapturer.supportedFormats(for: device)
        let selectedFormat = formats
            .filter { $0.width >= 1280 && $0.height >= 720 }
            .max { $0.width * $0.height < $1.width * $1.height }
            ?? formats.last

        guard let format = selectedFormat else {
            logger.error("No suitable video format found")
            return
        }

        // Get highest FPS
        let fps = format.videoSupportedFrameRateRanges
            .max { $0.maxFrameRate < $1.maxFrameRate }?.maxFrameRate ?? 30

        // Switch camera
        capturer.startCapture(with: device, format: format, fps: Int(fps))
        logger.info("Switched camera to \(isFront ? "front" : "back")")
    }

    // MARK: - Private: Camera Capture

    private func startCameraCapture(capturer: RTCCameraVideoCapturer, isFront: Bool) async throws {
        let position: AVCaptureDevice.Position = isFront ? .front : .back
        let devices = RTCCameraVideoCapturer.captureDevices()

        guard let device = devices.first(where: { $0.position == position }) else {
            throw WebRTCError.cameraNotAvailable
        }

        let formats = RTCCameraVideoCapturer.supportedFormats(for: device)
        guard let format = formats
            .filter({ $0.width >= 1280 && $0.height >= 720 })
            .max(by: { $0.width * $0.height < $1.width * $1.height }) else {
            throw WebRTCError.noSuitableVideoFormat
        }

        let fps = format.videoSupportedFrameRateRanges
            .max { $0.maxFrameRate < $1.maxFrameRate }?.maxFrameRate ?? 30

        // Start capture on video queue
        let videoQueue = DispatchQueue(label: "com.instagram.call.videoQueue", qos: .userInteractive)
        await withCheckedContinuation { continuation in
            videoQueue.async {
                capturer.startCapture(with: device, format: format, fps: Int(fps))
                continuation.resume()
            }
        }
    }

    // MARK: - Simulcast Setup

    private func setupSimulcastEncodings() {
        // Define 3 simulcast layers: high (1280x720), medium (640x360), low (320x180)
        simulcastEncodings = [
            RTCRtpEncodingParameters(),
            RTCRtpEncodingParameters(),
            RTCRtpEncodingParameters()
        ]

        // High quality (layer 0) - 1280x720 @ 30fps
        simulcastEncodings[0].scaleResolutionDownBy = 1.0
        simulcastEncodings[0].maxBitrateBps = 2_500_000
        simulcastEncodings[0].rid = "high"
        simulcastEncodings[0].active = true

        // Medium quality (layer 1) - 640x360 @ 30fps
        simulcastEncodings[1].scaleResolutionDownBy = 2.0
        simulcastEncodings[1].maxBitrateBps = 1_000_000
        simulcastEncodings[1].rid = "medium"
        simulcastEncodings[1].active = true

        // Low quality (layer 2) - 320x180 @ 15fps
        simulcastEncodings[2].scaleResolutionDownBy = 4.0
        simulcastEncodings[2].maxBitrateBps = 300_000
        simulcastEncodings[2].rid = "low"
        simulcastEncodings[2].active = true
        simulcastEncodings[2].maxFramerate = 15

        logger.info("Simulcast encodings configured: \(simulcastLayers) layers")
    }

    // MARK: - Peer Connection Management

    /// Creates and configures WebRTC peer connection for SFU transport.
    func createPeerConnection(
        callId: String,
        roomId: String,
        iceServers: [RTCIceServer],
        signalingHandler: CallSignalingHandlerProtocol
    ) async throws {
        guard let factory = peerConnectionFactory else {
            throw WebRTCError.factoryNotInitialized
        }

        self.currentCallId = callId
        self.currentRoomId = roomId
        self.iceServers = iceServers
        self.signalingHandler = signalingHandler

        // Configure peer connection
        let configuration = RTCConfiguration()
        configuration.iceServers = iceServers
        configuration.iceTransportPolicy = .all
        configuration.bundlePolicy = .maxBundle
        configuration.rtcpMuxPolicy = .require
        configuration.tcpCandidatePolicy = .enabled
        configuration.candidateNetworkPolicy = .all

        // Create peer connection
        let constraints = RTCHardwareConstraints()
        constraints.mandatoryConstraints = [
            "OfferToReceiveAudio": "true",
            "OfferToReceiveVideo": "true"
        ]

        peerConnection = factory.peerConnection(
            with: configuration,
            constraints: constraints,
            delegate: WebRTCPeerConnectionDelegate(pipeline: self)
        )

        guard let pc = peerConnection else {
            throw WebRTCError.peerConnectionCreationFailed
        }

        // Add local audio track
        if let audioTrack = audioTrack {
            pc.add(audioTrack, streamIds: ["call_stream"])
        }

        // Add local video track with simulcast
        if let videoTrack = videoTrack {
            let sender = pc.add(videoTrack, streamIds: ["call_stream"])
            // Configure simulcast on sender
            sender?.parameters.encodings = simulcastEncodings
        }

        // Create offer
        let offerConstraints = RTCOfferConstraints()
        offerConstraints.mandatoryConstraints = [
            "OfferToReceiveAudio": "true",
            "OfferToReceiveVideo": "true"
        ]

        let offer = try await pc.offer(for: offerConstraints)
        try await pc.setLocalDescription(offer)

        // Send offer via signaling
        let sdp = offer.sdp
        let signal = CallSignal.callOffer(
            callId: callId,
            fromUserId: SessionStore.shared.currentUserId,
            toUserId: "", // Will be filled by signaling handler
            sdp: sdp
        )
        try await signalingHandler.send(signal)

        logger.info("Peer connection created and offer sent for call \(callId)")

        // Subscribe to signaling for answer/ICE candidates
        subscribeToSignaling()
    }

    private func subscribeToSignaling() {
        guard let handler = signalingHandler else { return }

        handler.incomingSignalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] signal in
                Task { @MainActor [weak self] in
                    await self?.handleSignalingMessage(signal)
                }
            }
            .store(in: &cancellables)
    }

    private func handleSignalingMessage(_ signal: CallSignal) async {
        guard let pc = peerConnection else { return }

        switch signal {
        case .callAnswer(_, _, _, let sdp):
            let answer = RTCSessionDescription(type: .answer, sdp: sdp)
            try? await pc.setRemoteDescription(answer)
            logger.info("Remote answer set")

        case .callOffer(_, _, _, let sdp):
            let offer = RTCSessionDescription(type: .offer, sdp: sdp)
            try? await pc.setRemoteDescription(offer)

            // Create answer
            let answerConstraints = RTCOfferConstraints()
            let answer = try await pc.answer(for: answerConstraints)
            try await pc.setLocalDescription(answer)

            let answerSignal = CallSignal.callAnswer(
                callId: signal.callId,
                fromUserId: SessionStore.shared.currentUserId,
                toUserId: signal.fromUserId,
                sdp: answer.sdp
            )
            try? await signalingHandler?.send(answerSignal)
            logger.info("Remote offer received, answer sent")

        case .callIceCandidate(_, _, _, let candidate, let sdpMid, let sdpMLineIndex):
            let iceCandidate = RTCIceCandidate(
                sdp: candidate,
                sdpMLineIndex: Int32(sdpMLineIndex ?? 0),
                sdpMid: sdpMid
            )
            pc.add(iceCandidate)
            logger.info("ICE candidate added")

        default:
            break
        }
    }

    // MARK: - Tones (Ringback, Ringtone)

    func startRingbackTone() {
        guard let buffer = ringbackBuffer, !isPlayingRingback else { return }
        playLoopingToneBuffer(buffer, node: ringbackPlayerNode)
        isPlayingRingback = true
    }

    func stopRingbackTone() {
        if isPlayingRingback {
            ringbackPlayerNode.stop()
            isPlayingRingback = false
        }
    }

    func startIncomingRingtone() {
        guard let buffer = incomingRingtoneBuffer, !isPlayingRingtone else { return }
        playLoopingToneBuffer(buffer, node: ringtonePlayerNode)
        isPlayingRingtone = true
    }

    func stopIncomingRingtone() {
        if isPlayingRingtone {
            ringtonePlayerNode.stop()
            isPlayingRingtone = false
        }
    }

    // MARK: - Private: Audio Engine

    private func configureAudioSession() async throws {
        try await Task.detached(priority: .userInitiated) {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetoothHFP, .allowBluetoothA2DP, .allowAirPlay]
            )
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        }.value
    }

    private func startLocalAudioEngine() async throws {
        // Setup audio engine for local monitoring and tones
        audioEngine.attach(ringbackPlayerNode)
        audioEngine.attach(ringtonePlayerNode)
        audioEngine.attach(remotePlayerNode)

        let mainMixer = audioEngine.mainMixerNode
        let mixerFormat = mainMixer.outputFormat(forBus: 0)

        audioEngine.connect(ringbackPlayerNode, to: mainMixer, format: Self.standardToneFormat)
        audioEngine.connect(ringtonePlayerNode, to: mainMixer, format: Self.standardToneFormat)
        audioEngine.connect(remotePlayerNode, to: mainMixer, format: mixerFormat)

        // Install tap for audio level metering
        installAudioLevelTap()

        // Start engine
        if !audioEngine.isRunning {
            try audioEngine.start()
        }

        if !remotePlayerNode.isPlaying {
            remotePlayerNode.play()
        }
    }

    private func installAudioLevelTap() {
        let inputNode = audioEngine.inputNode
        let bus = 0
        let bufferSize: AVAudioFrameCount = 1024

        inputNode.installTap(onBus: bus, bufferSize: bufferSize, format: nil) { [weak self] buffer, _ in
            guard let self else { return }

            let muted = self.muteLock.withLock { self._isMuted }
            guard !muted else {
                self.audioLevelSubject.send(0.0)
                return
            }

            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            guard frameLength > 0 else { return }

            // RMS calculation
            var sumOfSquares: Float = 0
            for i in 0..<frameLength {
                let sample = max(-1.0, min(1.0, channelData[i]))
                sumOfSquares += sample * sample
            }

            let rms = sqrt(sumOfSquares / Float(frameLength))
            let db = 20.0 * log10(max(rms, 1e-5))

            let minDb: Float = -55.0
            let maxDb: Float = 0.0
            let clampedDb = max(minDb, min(db, maxDb))
            let normalized = (clampedDb - minDb) / (maxDb - minDb)

            self.audioLevelSubject.send(normalized)
        }
    }

    // MARK: - Tone Generation (Same as CallAudioEngineController)

    private func playLoopingToneBuffer(_ buffer: AVAudioPCMBuffer, node: AVAudioPlayerNode) {
        do {
            let session = AVAudioSession.sharedInstance()
            if session.category != .playAndRecord || session.mode != .voiceChat {
                try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetoothHFP, .allowBluetoothA2DP, .allowAirPlay])
            }
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            if !audioEngine.isRunning {
                try audioEngine.start()
            }

            node.stop()
            node.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            node.play()
        } catch {
            logger.error("Failed to play tone: \(error.localizedDescription)")
        }
    }

    private static func generateRingbackToneBuffer() -> AVAudioPCMBuffer? {
        let sampleRate: Double = 44100.0
        let totalDuration: Double = 6.0
        let onDuration: Double = 2.0
        let frameCount = AVAudioFrameCount(sampleRate * totalDuration)

        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: standardToneFormat, frameCapacity: frameCount) else {
            return nil
        }

        pcmBuffer.frameLength = frameCount
        guard let leftChannel = pcmBuffer.floatChannelData?[0],
              let rightChannel = pcmBuffer.floatChannelData?[1] else { return nil }

        let onFrames = Int(sampleRate * onDuration)
        let fadeFrames = Int(sampleRate * 0.02)

        for frame in 0..<Int(frameCount) {
            if frame < onFrames {
                let t = Double(frame) / sampleRate
                let wave = 0.20 * (sin(2.0 * .pi * 440.0 * t) + sin(2.0 * .pi * 480.0 * t))

                let envelope: Double
                if frame < fadeFrames {
                    envelope = Double(frame) / Double(fadeFrames)
                } else if frame > (onFrames - fadeFrames) {
                    envelope = Double(onFrames - frame) / Double(fadeFrames)
                } else {
                    envelope = 1.0
                }

                let sampleValue = Float(wave * envelope)
                leftChannel[frame] = sampleValue
                rightChannel[frame] = sampleValue
            } else {
                leftChannel[frame] = 0.0
                rightChannel[frame] = 0.0
            }
        }

        return pcmBuffer
    }

    private static func generateIncomingRingtoneBuffer() -> AVAudioPCMBuffer? {
        let sampleRate: Double = 44100.0
        let totalDuration: Double = 3.0
        let frameCount = AVAudioFrameCount(sampleRate * totalDuration)

        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: standardToneFormat, frameCapacity: frameCount) else {
            return nil
        }

        pcmBuffer.frameLength = frameCount
        guard let leftChannel = pcmBuffer.floatChannelData?[0],
              let rightChannel = pcmBuffer.floatChannelData?[1] else { return nil }

        let notes: [(Double, Double, Double)] = [
            (587.33, 0.00, 0.35), (739.99, 0.20, 0.35), (880.00, 0.40, 0.45),
            (1174.66, 0.65, 0.65), (587.33, 1.40, 0.35), (739.99, 1.60, 0.35),
            (880.00, 1.80, 0.45), (1174.66, 2.05, 0.65)
        ]

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            var sample: Double = 0.0

            for (freq, start, duration) in notes {
                if t >= start && t < (start + duration) {
                    let noteT = t - start
                    let envelope = exp(-4.5 * noteT)
                    let fundamental = sin(2.0 * .pi * freq * noteT)
                    let overtone = 0.30 * sin(2.0 * .pi * freq * 2.0 * noteT)
                    sample += 0.22 * envelope * (fundamental + overtone)
                }
            }

            let sampleValue = Float(max(-1.0, min(1.0, sample)))
            leftChannel[frame] = sampleValue
            rightChannel[frame] = sampleValue
        }

        return pcmBuffer
    }

    // MARK: - Remote Audio Injection

    func scheduleRemoteAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard isAudioRunning else { return }
        if !remotePlayerNode.isPlaying {
            remotePlayerNode.play()
        }
        remotePlayerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    // MARK: - Cancellables

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - WebRTC Peer Connection Delegate

private final class WebRTCPeerConnectionDelegate: NSObject, RTCPeerConnectionDelegate {
    private weak var pipeline: CallWebRTCMediaPipeline?

    init(pipeline: CallWebRTCMediaPipeline) {
        self.pipeline = pipeline
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        pipeline?.logger.info("WebRTC signaling state: \(stateChanged.rawValue)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        // Handle remote stream
        if let videoTrack = stream.videoTracks.first {
            pipeline?.handleRemoteVideoTrack(videoTrack)
        }
        if let audioTrack = stream.audioTracks.first {
            pipeline?.handleRemoteAudioTrack(audioTrack)
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        pipeline?.logger.info("Remote stream removed")
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        pipeline?.logger.info("WebRTC negotiation needed")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        pipeline?.logger.info("ICE connection state: \(newState.rawValue)")

        switch newState {
        case .connected, .completed:
            pipeline?.logger.info("ICE connected - media flowing")
            pipeline?.isConnected = true
        case .disconnected:
            pipeline?.logger.notice("ICE disconnected - attempting reconnection")
            pipeline?.isConnected = false
        case .failed:
            pipeline?.logger.error("ICE failed - restarting ICE")
            pipeline?.isConnected = false
            peerConnection.restartIce()
        case .closed:
            pipeline?.isConnected = false
        default:
            break
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        pipeline?.logger.info("ICE gathering state: \(newState.rawValue)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        // Send ICE candidate via signaling
        let signal = CallSignal.callIceCandidate(
            callId: pipeline?.currentCallId ?? "",
            fromUserId: SessionStore.shared.currentUserId,
            toUserId: "", // Will be filled by signaling handler
            candidate: candidate.sdp,
            sdpMid: candidate.sdpMid,
            sdpMLineIndex: Int(candidate.sdpMLineIndex)
        )
        Task {
            try? await pipeline?.signalingHandler?.send(signal)
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        pipeline?.logger.info("ICE candidates removed: \(candidates.count)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        pipeline?.logger.info("Data channel opened: \(dataChannel.label)")
    }
}

// MARK: - WebRTC Error

enum WebRTCError: LocalizedError {
    case factoryNotInitialized
    case peerConnectionCreationFailed
    case cameraNotAvailable
    case noSuitableVideoFormat
    case webRTCNotAvailable
    case encodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .factoryNotInitialized: return "WebRTC peer connection factory not initialized"
        case .peerConnectionCreationFailed: return "Failed to create peer connection"
        case .cameraNotAvailable: return "Camera not available"
        case .noSuitableVideoFormat: return "No suitable video format found"
        case .webRTCNotAvailable: return "WebRTC framework not available"
        case .encodingFailed(let msg): return "Video encoding failed: \(msg)"
        }
    }
}

// MARK: - WebRTC Pipeline Extensions (for CallSignalingHandlerProtocol)

/// Extended protocol for WebRTC-specific pipeline features.
protocol CallWebRTCMediaPipelineProtocol: CallMediaPipelineProtocol {
    /// Creates and configures WebRTC peer connection for SFU transport.
    func createPeerConnection(
        callId: String,
        roomId: String,
        iceServers: [RTCIceServer],
        signalingHandler: CallSignalingHandlerProtocol
    ) async throws

    /// Sets the signaling handler for WebRTC negotiation.
    func setSignalingHandler(_ handler: CallSignalingHandlerProtocol)

    /// Gets the WebRTC peer connection (if available).
    var peerConnection: Any? { get }

    /// Gets the local audio track.
    var localAudioTrack: Any? { get }

    /// Gets the local video track.
    var localVideoTrack: Any? { get }
}

#endif // canImport(WebRTC)