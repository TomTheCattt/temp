//
//  CallMediaPipelineProtocol.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Combine
import CoreMedia
import AVFoundation

// MARK: - CallMediaPipelineProtocol

/// Unified pluggable media pipeline interface for audio capture/playback and video capture/rendering.
/// Adheres to Clean Architecture, allowing AVFoundation or WebRTC implementations interchangeably.
protocol CallMediaPipelineProtocol: AnyObject, Sendable {

    // MARK: - Audio Control

    /// Starts audio engine, configuring VoiceProcessingIO (AEC, AGC, Noise Suppression).
    func startAudio() async throws

    /// Stops audio engine and releases audio taps.
    func stopAudio()

    /// Sets hardware and software microphone mute state.
    func setMuted(_ isMuted: Bool)

    /// Overrides audio output route between speaker and earpiece/receiver.
    func setSpeaker(_ isSpeaker: Bool)

    // MARK: - Video Control

    /// Starts dedicated camera capture session or high-fidelity synthetic generator.
    func startVideo(isFront: Bool) async throws

    /// Stops camera capture session.
    func stopVideo()

    /// Switches camera orientation between front-facing and back-facing.
    func switchCamera(isFront: Bool) async

    // MARK: - Publishers

    /// Emits normalized real-time audio RMS level in range `0.0 ... 1.0`.
    var audioLevelPublisher: AnyPublisher<Float, Never> { get }

    /// Emits local camera/synthetic CMSampleBuffers for Picture-in-Picture preview.
    var localSampleBufferPublisher: AnyPublisher<CMSampleBuffer, Never> { get }

    /// Emits remote party/synthetic loopback CMSampleBuffers for full-screen video rendering.
    var remoteSampleBufferPublisher: AnyPublisher<CMSampleBuffer, Never> { get }

    // MARK: - Tones

    /// Starts looping outgoing ringback tone ("tuut... tuut...").
    func startRingbackTone()

    /// Stops outgoing ringback tone.
    func stopRingbackTone()

    /// Starts looping incoming call ringtone chime.
    func startIncomingRingtone()

    /// Stops incoming call ringtone chime.
    func stopIncomingRingtone()

    /// Replays the last captured frame to local subscribers if available.
    func replayLastSampleBuffer()
}

// MARK: - Default Protocol Extensions

extension CallMediaPipelineProtocol {
    func replayLastSampleBuffer() {}
}

// MARK: - Default Protocol Extensions

extension CallMediaPipelineProtocol {
    func startRingbackTone() {}
    func stopRingbackTone() {}
    func startIncomingRingtone() {}
    func stopIncomingRingtone() {}
}

// MARK: - DefaultCallMediaPipeline (Unified Facade)

/// Unified facade implementation coordinating CallAudioEngineController and CallVideoCaptureController.
@MainActor
final class DefaultCallMediaPipeline: CallMediaPipelineProtocol, @unchecked Sendable {

    // MARK: - Singleton

    static let shared = DefaultCallMediaPipeline()

    // MARK: - Sub-controllers

    let audioController: CallAudioEngineController
    let videoController: CallVideoCaptureController

    // MARK: - Init

    init(
        audioController: CallAudioEngineController? = nil,
        videoController: CallVideoCaptureController? = nil
    ) {
        self.audioController = audioController ?? CallAudioEngineController.shared
        self.videoController = videoController ?? CallVideoCaptureController.shared
    }

    // MARK: - Audio Delegation

    func startAudio() async throws {
        try await audioController.startAudio()
    }

    func stopAudio() {
        audioController.stopAudio()
    }

    func setMuted(_ isMuted: Bool) {
        audioController.setMuted(isMuted)
    }

    func setSpeaker(_ isSpeaker: Bool) {
        audioController.setSpeaker(isSpeaker)
    }

    func startRingbackTone() {
        audioController.startRingbackTone()
    }

    func stopRingbackTone() {
        audioController.stopRingbackTone()
    }

    func startIncomingRingtone() {
        audioController.startIncomingRingtone()
    }

    func stopIncomingRingtone() {
        audioController.stopIncomingRingtone()
    }

    // MARK: - Video Delegation

    func startVideo(isFront: Bool) async throws {
        try await videoController.startVideo(isFront: isFront)
    }

    func stopVideo() {
        videoController.stopVideo()
    }

    func switchCamera(isFront: Bool) async {
        await videoController.switchCamera(isFront: isFront)
    }

    func replayLastSampleBuffer() {
        videoController.replayLastSampleBuffer()
    }

    // MARK: - Publishers

    nonisolated var audioLevelPublisher: AnyPublisher<Float, Never> {
        audioController.audioLevelPublisher
    }

    nonisolated var localSampleBufferPublisher: AnyPublisher<CMSampleBuffer, Never> {
        videoController.localSampleBufferPublisher
    }

    nonisolated var remoteSampleBufferPublisher: AnyPublisher<CMSampleBuffer, Never> {
        videoController.remoteSampleBufferPublisher
    }
}
