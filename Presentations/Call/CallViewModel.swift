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
        // TODO: Implement call onAppear logic from scratch
    }

    func startOutgoingCall() async {
        // TODO: Implement startOutgoingCall logic from scratch
    }

    // MARK: - User Controls

    func accept() async {
        // TODO: Implement accept call logic from scratch
    }

    func reject() async {
        // TODO: Implement reject call logic from scratch
    }

    func hangup() async {
        // TODO: Implement hangup call logic from scratch
    }

    func toggleMute() {
        isMuted.toggle()
        // TODO: Implement toggleMute logic from scratch
    }

    func toggleSpeaker() {
        isSpeakerOn.toggle()
        // TODO: Implement toggleSpeaker logic from scratch
    }

    func flipCamera() {
        isFrontCamera.toggle()
        // TODO: Implement flipCamera logic from scratch
    }

    func toggleCamera() {
        isCameraOff.toggle()
        // TODO: Implement toggleCamera logic from scratch
    }

    func upgradeToVideo() {
        hasVideo = true
        // TODO: Implement upgradeToVideo logic from scratch
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
