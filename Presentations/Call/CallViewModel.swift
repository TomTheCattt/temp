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

// MARK: - CallTaskCoordinator

private final class CallTaskCoordinator: @unchecked Sendable {
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
    var hasVideo: Bool
    var isFrontCamera: Bool = true
    var isCameraOff: Bool = false

    let remoteUserId: String
    let remoteName: String

    // MARK: - Private

    private let callService: CallService
    private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored
    private let taskCoordinator = CallTaskCoordinator()
    private let logger = AppLogger.general

    // MARK: - Init

    init(
        remoteUserId: String,
        remoteName: String,
        hasVideo: Bool,
        callService: CallService? = nil
    ) {
        self.remoteUserId = remoteUserId
        self.remoteName = remoteName
        self.hasVideo = hasVideo
        let service = callService ?? CallService.shared
        self.callService = service
        self.callState = service.currentCallState

        subscribeToState()
        setupSensorsAndCamera()
    }

    deinit {
        taskCoordinator.cancelAll()
        Task { @MainActor in
            UIDevice.current.isProximityMonitoringEnabled = false
            UIApplication.shared.isIdleTimerDisabled = false
            CameraService.shared.stop()
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
        } catch {
            logger.error("Failed to initiate outgoing call: \(error.localizedDescription)")
        }
    }

    // MARK: - User Controls

    func accept() async {
        HapticFeedbackSafe.impact(.medium)
        try? await callService.acceptIncomingCall()
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
    }

    func toggleSpeaker() async {
        HapticFeedbackSafe.selection()
        try? await callService.toggleSpeaker()
        isSpeakerOn = callService.currentCall?.isSpeakerOn ?? false
        updateProximitySensor()
    }

    func flipCamera() {
        guard hasVideo else { return }
        HapticFeedbackSafe.selection()
        isFrontCamera.toggle()
        CameraService.shared.switchCamera(isFront: isFrontCamera)
    }

    func toggleCamera() {
        guard hasVideo else { return }
        HapticFeedbackSafe.selection()
        isCameraOff.toggle()
        if isCameraOff {
            CameraService.shared.stop()
        } else {
            CameraService.shared.start()
        }
    }

    func upgradeToVideo() {
        guard !hasVideo else { return }
        HapticFeedbackSafe.impact(.medium)
        hasVideo = true
        Task {
            _ = await CameraService.shared.configureSession(isFront: true)
            CameraService.shared.start()
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

    private func handleStateChange(_ state: CallState) {
        switch state {
        case .connected:
            HapticFeedbackSafe.impact(.medium)
            startDurationTimer()
            updateProximitySensor()
            updateIdleTimer()

        case .ended:
            HapticFeedbackSafe.notification(.warning)
            stopDurationTimer()
            cleanupSensorsAndCamera()
            scheduleAutoDismiss()

        default:
            break
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
                _ = await CameraService.shared.configureSession(isFront: true)
                CameraService.shared.start()
            }
        }
        updateProximitySensor()
        updateIdleTimer()
    }

    private func cleanupSensorsAndCamera() {
        UIDevice.current.isProximityMonitoringEnabled = false
        UIApplication.shared.isIdleTimerDisabled = false
        if hasVideo {
            CameraService.shared.stop()
        }
    }

    private func updateProximitySensor() {
        // Enable proximity sensor only for audio calls in non-speaker mode when connected
        let shouldEnable = !hasVideo && !isSpeakerOn && callState == .connected
        UIDevice.current.isProximityMonitoringEnabled = shouldEnable
    }

    private func updateIdleTimer() {
        // Prevent screen auto-locking during connected video calls
        let shouldDisableIdle = hasVideo && callState == .connected
        UIApplication.shared.isIdleTimerDisabled = shouldDisableIdle
    }
}
