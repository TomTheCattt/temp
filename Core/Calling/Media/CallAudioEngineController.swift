//
//  CallAudioEngineController.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import AVFoundation
import Combine

// MARK: - CallAudioEngineController

/// Dedicated native audio controller managing low-latency voice capture, VoiceProcessingIO (AEC, AGC, NS),
/// real-time RMS decibel metering, hardware mute, speaker routing, and synthetic tone generation.
@MainActor
final class CallAudioEngineController: @unchecked Sendable {

    // MARK: - Singleton

    static let shared = CallAudioEngineController()

    // MARK: - Publishers

    /// Emits normalized real-time audio RMS level in range `0.0 ... 1.0`.
    nonisolated var audioLevelPublisher: AnyPublisher<Float, Never> {
        audioLevelSubject.eraseToAnyPublisher()
    }

    private nonisolated let audioLevelSubject = CurrentValueSubject<Float, Never>(0.0)

    // MARK: - Audio Graph

    private let engine = AVAudioEngine()
    private let tonePlayerNode = AVAudioPlayerNode()
    private let remotePlayerNode = AVAudioPlayerNode()

    /// Guaranteed valid stereo 44.1kHz tone format matching synthesized ringback and chime buffers.
    private static let standardToneFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!

    // MARK: - State

    private var isTapInstalled = false
    private var isRunning = false
    private var isMuted = false
    private var isSpeaker = false
    private var isPlayingTone = false

    // MARK: - Tone Buffers (Cached in RAM)

    private lazy var ringbackBuffer: AVAudioPCMBuffer? = {
        Self.generateRingbackToneBuffer()
    }()

    private lazy var incomingRingtoneBuffer: AVAudioPCMBuffer? = {
        Self.generateIncomingRingtoneBuffer()
    }()

    // MARK: - Init & Deinit

    init() {
        setupEngineGraph()
    }

    deinit {
        // Safe synchronous cleanup if deallocated
        if isTapInstalled {
            engine.inputNode.removeTap(onBus: 0)
        }
        if engine.isRunning {
            engine.stop()
        }
    }

    // MARK: - Engine Setup

    private func setupEngineGraph() {
        engine.attach(tonePlayerNode)
        engine.attach(remotePlayerNode)

        let mainMixer = engine.mainMixerNode
        let mixerFormat = mainMixer.outputFormat(forBus: 0)
        let remoteFormat = (mixerFormat.sampleRate > 0 && mixerFormat.channelCount > 0)
            ? mixerFormat
            : Self.standardToneFormat

        // Connect tonePlayerNode with guaranteed valid stereo toneFormat matching synthesized tone buffers
        engine.connect(tonePlayerNode, to: mainMixer, format: Self.standardToneFormat)
        engine.connect(remotePlayerNode, to: mainMixer, format: remoteFormat)
    }

    // MARK: - Public Audio Control

    /// Configures audio session for voice chat, enables hardware VoiceProcessingIO (AEC, AGC),
    /// installs microphone tap, and starts the audio engine.
    func startAudio() async throws {
        // 1. Stop any currently playing standalone tones
        internalStopTone()

        // 2. Configure system audio session
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.allowBluetoothHFP, .allowBluetoothA2DP, .allowAirPlay]
        )
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        // 3. Enable VoiceProcessingIO for Acoustic Echo Cancellation & Noise Suppression
        let inputNode = engine.inputNode
        do {
            try inputNode.setVoiceProcessingEnabled(true)
        } catch {
            AppLogger.general.notice("VoiceProcessingIO not supported on this device/simulator: \(error.localizedDescription)")
        }

        // Apply hardware mute state
        inputNode.isVoiceProcessingInputMuted = isMuted

        // Apply current speaker route
        try? session.overrideOutputAudioPort(isSpeaker ? .speaker : .none)

        // 4. Install 1024-sample floating point tap for real-time RMS metering
        installMicrophoneTapIfNeeded(inputNode: inputNode)

        // 5. Start audio engine
        if !engine.isRunning {
            try engine.start()
        }

        // 6. Start remote player node for incoming PCM playback
        if !remotePlayerNode.isPlaying {
            remotePlayerNode.play()
        }

        isRunning = true
    }

    /// Stops audio engine, removes microphone tap, and releases audio resources.
    func stopAudio() {
        internalStopTone()

        if isTapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }

        if remotePlayerNode.isPlaying {
            remotePlayerNode.stop()
        }

        if engine.isRunning {
            engine.stop()
        }

        isRunning = false
        audioLevelSubject.send(0.0)

        // Reset voice processing mute
        engine.inputNode.isVoiceProcessingInputMuted = false
    }

    /// Sets hardware microphone mute and resets audio level to 0 when muted.
    func setMuted(_ isMuted: Bool) {
        self.isMuted = isMuted
        engine.inputNode.isVoiceProcessingInputMuted = isMuted

        if isMuted {
            audioLevelSubject.send(0.0)
        }
    }

    /// Overrides output audio port to speaker or earpiece.
    func setSpeaker(_ isSpeaker: Bool) {
        self.isSpeaker = isSpeaker
        let session = AVAudioSession.sharedInstance()
        try? session.overrideOutputAudioPort(isSpeaker ? .speaker : .none)
    }

    // MARK: - Tone Generation

    /// Plays looping outgoing ringback tone ("tuut... tuut...": 440Hz + 480Hz).
    func startRingbackTone() {
        guard let buffer = ringbackBuffer else { return }
        playLoopingToneBuffer(buffer)
    }

    /// Stops outgoing ringback tone.
    func stopRingbackTone() {
        internalStopTone()
    }

    /// Plays looping incoming call ringtone chime.
    func startIncomingRingtone() {
        guard let buffer = incomingRingtoneBuffer else { return }
        playLoopingToneBuffer(buffer)
    }

    /// Stops incoming call ringtone.
    func stopIncomingRingtone() {
        internalStopTone()
    }

    // MARK: - Remote Audio Injection

    /// Schedules an incoming PCM audio buffer directly onto the remote player node.
    func scheduleRemoteAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard isRunning else { return }
        if !remotePlayerNode.isPlaying {
            remotePlayerNode.play()
        }
        remotePlayerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    // MARK: - Private Tap Installation

    private func installMicrophoneTapIfNeeded(inputNode: AVAudioInputNode) {
        guard !isTapInstalled else { return }

        #if targetEnvironment(simulator)
        AppLogger.general.notice("Simulator environment detected: skipping hardware microphone tap")
        return
        #else
        let bus = 0
        let hwFormat = inputNode.inputFormat(forBus: bus)
        let tapFormat = inputNode.outputFormat(forBus: bus)

        guard hwFormat.sampleRate > 0 && hwFormat.channelCount > 0,
              tapFormat.sampleRate > 0 && tapFormat.channelCount > 0 else {
            AppLogger.general.notice("Microphone input format invalid for tap (hw: \(hwFormat), tap: \(tapFormat))")
            return
        }

        let bufferSize: AVAudioFrameCount = 1024

        inputNode.installTap(onBus: bus, bufferSize: bufferSize, format: tapFormat) { [weak self] buffer, _ in
            guard let self else { return }

            guard !self.isMuted else {
                self.audioLevelSubject.send(0.0)
                return
            }

            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            guard frameLength > 0 else { return }

            // Zero-allocation RMS decibel metering
            var sumOfSquares: Float = 0
            for i in 0..<frameLength {
                let sample = channelData[i]
                sumOfSquares += sample * sample
            }

            let rms = sqrt(sumOfSquares / Float(frameLength))
            // Decibel formula: 20 * log10(max(rms, 1e-5))
            let db = 20.0 * log10(max(rms, 1e-5))

            // Normalize from [-55 dB, 0 dB] -> [0.0, 1.0]
            let minDb: Float = -55.0
            let maxDb: Float = 0.0
            let clampedDb = max(minDb, min(db, maxDb))
            let normalized = (clampedDb - minDb) / (maxDb - minDb)

            self.audioLevelSubject.send(normalized)
        }

        isTapInstalled = true
        #endif
    }

    // MARK: - Private Tone Playback Helper

    private func playLoopingToneBuffer(_ buffer: AVAudioPCMBuffer) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .voiceChat, options: [.mixWithOthers])
            try session.setActive(true)

            if !engine.isRunning {
                try engine.start()
            }

            tonePlayerNode.stop()
            tonePlayerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            tonePlayerNode.play()
            isPlayingTone = true
        } catch {
            AppLogger.general.error("Failed to play tone: \(error.localizedDescription)")
        }
    }

    private func internalStopTone() {
        if isPlayingTone {
            tonePlayerNode.stop()
            isPlayingTone = false
        }
    }

    // MARK: - Tone Synthesis Generators

    /// Synthesizes standard 440Hz + 480Hz dual-frequency ringback tone with 2s ON / 4s OFF cadence in stereo.
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
        let fadeFrames = Int(sampleRate * 0.02) // 20ms fade in/out to avoid clicks

        for frame in 0..<Int(frameCount) {
            if frame < onFrames {
                let t = Double(frame) / sampleRate
                let wave = 0.20 * (sin(2.0 * .pi * 440.0 * t) + sin(2.0 * .pi * 480.0 * t))

                // Smooth windowing
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

    /// Synthesizes high-fidelity multi-harmonic melodic chime pattern for incoming calls in stereo.
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

        // Melodic notes sequence: (Frequency, StartTime, Duration)
        let notes: [(Double, Double, Double)] = [
            (587.33, 0.00, 0.35), // D5
            (739.99, 0.20, 0.35), // F#5
            (880.00, 0.40, 0.45), // A5
            (1174.66, 0.65, 0.65), // D6
            (587.33, 1.40, 0.35), // D5 repeat
            (739.99, 1.60, 0.35), // F#5 repeat
            (880.00, 1.80, 0.45), // A5 repeat
            (1174.66, 2.05, 0.65)  // D6 repeat
        ]

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            var sample: Double = 0.0

            for (freq, start, duration) in notes {
                if t >= start && t < (start + duration) {
                    let noteT = t - start
                    // Harmonic overtone synthesis + exponential decay
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
}
