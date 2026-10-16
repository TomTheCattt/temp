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
        hasVideo: Bool,
        callService: CallService? = nil,
        pipeline: CallMediaPipelineProtocol? = nil
    ) {
        self.remoteUserId = remoteUserId
        self.remoteName = remoteName
        self.hasVideo = hasVideo
        // Standard Instagram video call defaults to speaker output
        if hasVideo {
            self.isSpeakerOn = true
        }

        let service = callService ?? CallService.shared
        self.callService = service
        self.callState = service.currentCallState

        let mediaPipeline = pipeline ?? DefaultCallMediaPipeline.shared
        self.pipeline = mediaPipeline

        subscribeToState()
        subscribeToMedia()
        setupSensorsAndCamera()
    }

    deinit {
        taskCoordinator.cancelAll()
        let localPipeline = pipeline
        Task { @MainActor in
            UIDevice.current.isProximityMonitoringEnabled = false
            UIApplication.shared.isIdleTimerDisabled = false
            localPipeline.stopVideo()
            localPipeline.stopAudio()
        }
    }

    // MARK: - Lifecycle Actions

    /// Automatically initiates outgoing call if state is currently idle.
    func onAppear() async {
        if callService.currentCallState == .idle {
            await startOutgoingCall()
        }
    }

    func startOutgoingCall() async {
        do {
            try await callService.initiateCall(
                to: remoteUserId,
                name: remoteName,
                hasVideo: hasVideo
            )
            // Start audio & video capture for outgoing call
            try? await pipeline.startAudio()
            if hasVideo && !isCameraOff {
                try? await pipeline.startVideo(isFront: isFrontCamera)
            }
            if isSpeakerOn {
                pipeline.setSpeaker(true)
            }
        } catch {
            logger.error("Failed to initiate outgoing call: \(error.localizedDescription)")
        }
    }

    // MARK: - User Controls

    func accept() async {
        HapticFeedbackSafe.impact(.medium)
        try? await callService.acceptIncomingCall()
        try? await pipeline.startAudio()
        if hasVideo && !isCameraOff {
            try? await pipeline.startVideo(isFront: isFrontCamera)
        }
        if isSpeakerOn {
            pipeline.setSpeaker(true)
        }
    }

    func reject() async {
        HapticFeedbackSafe.notification(.warning)
        try? await callService.rejectIncomingCall()
    }

    func hangup() async {
        HapticFeedbackSafe.notification(.warning)
        try? await callService.hangup()
    }

    func toggleMute() async {
        HapticFeedbackSafe.selection()
        try? await callService.toggleMute()
        isMuted = callService.currentCall?.isMuted ?? false
        pipeline.setMuted(isMuted)
    }

    func toggleSpeaker() async {
        HapticFeedbackSafe.selection()
        try? await callService.toggleSpeaker()
        isSpeakerOn = callService.currentCall?.isSpeakerOn ?? false
        pipeline.setSpeaker(isSpeakerOn)
        updateProximitySensor()
    }

    func flipCamera() {
        guard hasVideo else { return }
        HapticFeedbackSafe.selection()
        isFrontCamera.toggle()
        Task {
            await pipeline.switchCamera(isFront: isFrontCamera)
        }
    }

    func toggleCamera() {
        guard hasVideo else { return }
        HapticFeedbackSafe.selection()
        isCameraOff.toggle()
        if isCameraOff {
            pipeline.stopVideo()
        } else {
            Task {
                try? await pipeline.startVideo(isFront: isFrontCamera)
            }
        }
    }

    func upgradeToVideo() {
        guard !hasVideo else { return }
        HapticFeedbackSafe.impact(.medium)
        hasVideo = true
        isSpeakerOn = true
        Task {
            try? await callService.upgradeToVideo()
            try? await pipeline.startVideo(isFront: true)
            pipeline.setSpeaker(true)
        }
        updateIdleTimer()
        updateProximitySensor()
    }

    func dismissCall() {
        cleanupSensorsAndCamera()
        shouldDismiss = true
        AppRouter.shared.dismiss()
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
        case .connected:
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
            HapticFeedbackSafe.notification(.warning)
            stopDurationTimer()
            cleanupSensorsAndCamera()
            scheduleAutoDismiss()

        default:
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
