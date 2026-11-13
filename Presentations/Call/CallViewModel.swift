//
//  CallViewModel.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Combine
import UIKit
import AVFoundation
import CoreMedia

// MARK: - CallTaskCoordinator

private nonisolated final class CallTaskCoordinator: @unchecked Sendable {
    var durationTimer: Task<Void, Never>?
    var autoDismissTask: Task<Void, Never>?

    func cancelAll() {
        durationTimer?.cancel()
        durationTimer = nil
        autoDismissTask?.cancel()
        autoDismissTask = nil
    }
}

// MARK: - CallViewModel

@MainActor
@Observable
final class CallViewModel {

    // MARK: - State

    private(set) var callState: CallState = .idle
    private(set) var isMuted = false
    private(set) var isSpeakerOn = false
    private(set) var callDuration = "00:00"
    private(set) var shouldDismiss = false
    private(set) var audioLevel: Float = 0.0
    var hasVideo: Bool
    var isFrontCamera: Bool = true
    var isCameraOff: Bool = false

    let remoteUserId: String
    let remoteName: String
    let remoteAvatarURL: URL?

    // MARK: - Publishers for View

    var localSampleBufferPublisher: AnyPublisher<CMSampleBuffer, Never> {
        pipeline.localSampleBufferPublisher
    }

    var remoteSampleBufferPublisher: AnyPublisher<CMSampleBuffer, Never> {
        pipeline.remoteSampleBufferPublisher
    }

    var audioLevelPublisher: AnyPublisher<Float, Never> {
        pipeline.audioLevelPublisher
    }

    // MARK: - Private

    private let callService: CallService
    private let pipeline: CallMediaPipelineProtocol
    private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored
    private let taskCoordinator = CallTaskCoordinator()
    private let logger = AppLogger.general

    // MARK: - Init

    init(
        remoteUserId: String,
        remoteName: String,
        remoteAvatarURL: URL? = nil,
        hasVideo: Bool,
        callService: CallService? = nil,
        pipeline: CallMediaPipelineProtocol? = nil
    ) {
        self.remoteUserId = remoteUserId
        self.remoteName = remoteName
        self.remoteAvatarURL = remoteAvatarURL
        self.hasVideo = hasVideo
        // Standard Instagram video call defaults to speaker output
        if hasVideo {
            self.isSpeakerOn = true
        }

        let service = callService ?? CallService.shared
        self.callService = service
        self.callState = service.currentCallState
        if let call = service.currentCall {
            self.isMuted = call.isMuted
            self.isSpeakerOn = call.isSpeakerOn
            self.hasVideo = call.hasVideo
        }

        let mediaPipeline = pipeline ?? DefaultCallMediaPipeline.shared
        self.pipeline = mediaPipeline

        subscribeToState()
        subscribeToMedia()
        setupSensorsAndCamera()
    }

    deinit {
        taskCoordinator.cancelAll()
        Task { @MainActor in
            UIDevice.current.isProximityMonitoringEnabled = false
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: - Lifecycle Actions

    /// Automatically initiates outgoing call if state is currently idle.
    // MARK: - Actions

    func onAppear() async {
        // If we're in an incoming ringing state, start the incoming ringtone
        if callState == .incomingRinging {
            pipeline.startIncomingRingtone()
        }

        // If we're in outgoing ringing, start ringback
        if callState == .ringing {
            pipeline.startRingbackTone()
        }

        // If connected, ensure media is started
        if callState == .connected {
            await startMediaForConnectedCall()
        }
    }

    func startOutgoingCall() async {
        guard callState == .idle,
              let call = callService.currentCall,
              call.isOutgoing else { return }

        do {
            // Start media pipeline
            try await pipeline.startAudio()
            if hasVideo && !isCameraOff {
                try await pipeline.startVideo(isFront: isFrontCamera)
            }

            // Configure audio
            pipeline.setSpeaker(isSpeakerOn)
            pipeline.setMuted(isMuted)

            // Send call initiate signal
            _ = SessionStore.shared.currentUserId
            try await callService.initiateCall(
                to: call.remoteUserId,
                name: call.remoteName,
                avatarURL: call.remoteAvatarURL,
                hasVideo: hasVideo
            )
        } catch {
            logger.error("Failed to start outgoing call: \(error.localizedDescription)")
            dismissCall()
        }
    }

    // MARK: - User Controls

    func accept() async {
        do {
            try await callService.acceptIncomingCall()
            await startMediaForConnectedCall()
        } catch {
            logger.error("Failed to accept call: \(error.localizedDescription)")
            dismissCall()
        }
    }

    func reject() async {
        do {
            try await callService.rejectIncomingCall()
        } catch {
            logger.error("Failed to reject call: \(error.localizedDescription)")
        }
        dismissCall()
    }

    func hangup() async {
        do {
            try await callService.hangup()
        } catch {
            logger.error("Failed to hangup: \(error.localizedDescription)")
        }
        dismissCall()
    }

    func toggleMute() {
        isMuted.toggle()
        pipeline.setMuted(isMuted)
        callService.setMuted(isMuted)
    }

    func toggleSpeaker() {
        isSpeakerOn.toggle()
        pipeline.setSpeaker(isSpeakerOn)
        callService.setSpeaker(isSpeakerOn)
    }

    func flipCamera() {
        isFrontCamera.toggle()
        Task {
            await pipeline.switchCamera(isFront: isFrontCamera)
            await callService.flipCamera(isFront: isFrontCamera)
        }
    }

    func toggleCamera() {
        isCameraOff.toggle()
        Task {
            await callService.toggleCamera(isOff: isCameraOff)
        }
    }

    func upgradeToVideo() {
        guard !hasVideo, callState == .connected else { return }
        hasVideo = true
        Task {
            do {
                try await callService.upgradeToVideo()
                if !isCameraOff {
                    try await pipeline.startVideo(isFront: isFrontCamera)
                }
            } catch {
                logger.error("Failed to upgrade to video: \(error.localizedDescription)")
                hasVideo = false
            }
        }
    }

    // MARK: - Private Helpers

    private func startMediaForConnectedCall() async {
        do {
            try await pipeline.startAudio()
            if hasVideo && !isCameraOff {
                try await pipeline.startVideo(isFront: isFrontCamera)
            }
            pipeline.setSpeaker(isSpeakerOn)
            pipeline.setMuted(isMuted)
        } catch {
            logger.error("Failed to start media for connected call: \(error.localizedDescription)")
        }
    }

    func dismissCall() {
        UIDevice.current.isProximityMonitoringEnabled = false
        UIApplication.shared.isIdleTimerDisabled = false
        shouldDismiss = true
        AppRouter.shared.dismiss()
    }

    /// Replays the last sample buffer to refresh local PiP if needed.
    func replayLastSampleBuffer() {
        pipeline.replayLastSampleBuffer()
    }

    // MARK: - Private: Subscriptions

    private func subscribeToState() {
        // Observe CallState
        callService.callStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.callState = state
                self.handleStateChange(state)
            }
            .store(in: &cancellables)

        // Observe ActiveCall updates (mute, speaker)
        callService.currentCallPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] call in
                guard let self else { return }
                if let call {
                    self.isMuted = call.isMuted
                    self.isSpeakerOn = call.isSpeakerOn
                    if call.hasVideo != self.hasVideo {
                        self.hasVideo = call.hasVideo
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func subscribeToMedia() {
        pipeline.audioLevelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.audioLevel = level
            }
            .store(in: &cancellables)
    }

    private func handleStateChange(_ state: CallState) {
        switch state {
        case .ringing:
            if callService.currentCall?.isOutgoing == true {
                pipeline.startRingbackTone()
            }
            updateProximitySensor()
            updateIdleTimer()

        case .incomingRinging:
            pipeline.startIncomingRingtone()
            updateProximitySensor()
            updateIdleTimer()

        case .connecting:
            pipeline.stopRingbackTone()
            pipeline.stopIncomingRingtone()
            updateProximitySensor()
            updateIdleTimer()

        case .connected:
            pipeline.stopRingbackTone()
            pipeline.stopIncomingRingtone()
            HapticFeedbackSafe.impact(.medium)
            startDurationTimer()
            updateProximitySensor()
            updateIdleTimer()
            Task {
                try? await pipeline.startAudio()
                if hasVideo && !isCameraOff {
                    try? await pipeline.startVideo(isFront: isFrontCamera)
                }
                pipeline.setSpeaker(isSpeakerOn)
                pipeline.setMuted(isMuted)
            }

        case .ended:
            pipeline.stopRingbackTone()
            pipeline.stopIncomingRingtone()
            HapticFeedbackSafe.notification(.warning)
            stopDurationTimer()
            cleanupSensorsAndCamera()
            scheduleAutoDismiss()

        default:
            pipeline.stopRingbackTone()
            pipeline.stopIncomingRingtone()
            updateProximitySensor()
            updateIdleTimer()
        }
    }

    // MARK: - Private: Duration Timer

    private func startDurationTimer() {
        stopDurationTimer()
        let startDate = callService.currentCall?.connectedAt ?? Date()

        taskCoordinator.durationTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self, !Task.isCancelled else { return }

                let elapsed = Int(Date().timeIntervalSince(startDate))
                let seconds = elapsed % 60
                if elapsed >= 3600 {
                    let hours = elapsed / 3600
                    let minutes = (elapsed % 3600) / 60
                    self.callDuration = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
                } else {
                    let minutes = elapsed / 60
                    self.callDuration = String(format: "%02d:%02d", minutes, seconds)
                }
            }
        }
    }

    private func stopDurationTimer() {
        taskCoordinator.durationTimer?.cancel()
        taskCoordinator.durationTimer = nil
    }

    // MARK: - Private: Auto Dismiss on End

    private func scheduleAutoDismiss() {
        taskCoordinator.autoDismissTask?.cancel()
        taskCoordinator.autoDismissTask = Task { [weak self] in
            // Wait 1.5s so user can read end reason status
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard let self, !Task.isCancelled else { return }
            self.dismissCall()
        }
    }

    // MARK: - Private: Sensors & Camera Setup

    private func setupSensorsAndCamera() {
        if hasVideo {
            Task {
                try? await pipeline.startVideo(isFront: true)
            }
        }
        updateProximitySensor()
        updateIdleTimer()
    }

    private func cleanupSensorsAndCamera() {
        UIDevice.current.isProximityMonitoringEnabled = false
        UIApplication.shared.isIdleTimerDisabled = false
        pipeline.stopVideo()
        pipeline.stopAudio()
    }

    private func updateProximitySensor() {
        // Enable proximity sensor only for audio calls in non-speaker mode during active call phases
        let shouldEnable = !hasVideo && !isSpeakerOn && (callState == .initiating || callState == .ringing || callState == .connecting || callState == .connected)
        UIDevice.current.isProximityMonitoringEnabled = shouldEnable
    }

    private func updateIdleTimer() {
        // Prevent screen auto-locking during connected video calls
        let shouldDisableIdle = hasVideo && callState == .connected
        UIApplication.shared.isIdleTimerDisabled = shouldDisableIdle
    }
}
