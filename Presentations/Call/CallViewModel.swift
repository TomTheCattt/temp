//
//  CallViewModel.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Combine

// MARK: - CallViewModel

@MainActor
@Observable
final class CallViewModel {

    // MARK: - State

    private(set) var callState: CallState = .idle
    private(set) var isMuted = false
    private(set) var isSpeakerOn = false
    private(set) var callDuration = "00:00"

    let remoteUserId: String
    let remoteName: String
    let hasVideo: Bool

    // MARK: - Private

    private let callService: CallService
    private var cancellables = Set<AnyCancellable>()
    private var durationTimer: Task<Void, Never>?

    // MARK: - Init

    init(
        remoteUserId: String,
        remoteName: String,
        hasVideo: Bool,
        callService: CallService = .shared
    ) {
        self.remoteUserId = remoteUserId
        self.remoteName = remoteName
        self.hasVideo = hasVideo
        self.callService = callService

        subscribeToState()
    }

    // MARK: - Actions

    func accept() async {
        try? await callService.acceptIncomingCall()
    }

    func reject() async {
        try? await callService.rejectIncomingCall()
    }

    func hangup() async {
        try? await callService.hangup()
    }

    func toggleMute() async {
        try? await callService.toggleMute()
        isMuted = callService.currentCall?.isMuted ?? false
    }

    func toggleSpeaker() async {
        try? await callService.toggleSpeaker()
        isSpeakerOn = callService.currentCall?.isSpeakerOn ?? false
    }

    func flipCamera() {
        // In production: switch front/back camera on WebRTC video track
    }

    // MARK: - Private

    private func subscribeToState() {
        callService.callStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.callState = state

                if state == .connected {
                    self.startDurationTimer()
                } else if case .ended = state {
                    self.stopDurationTimer()
                }
            }
            .store(in: &cancellables)
    }

    private func startDurationTimer() {
        stopDurationTimer()
        let startDate = Date()

        durationTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self, !Task.isCancelled else { return }

                let elapsed = Int(Date().timeIntervalSince(startDate))
                let minutes = elapsed / 60
                let seconds = elapsed % 60
                self.callDuration = String(format: "%02d:%02d", minutes, seconds)
            }
        }
    }

    private func stopDurationTimer() {
        durationTimer?.cancel()
        durationTimer = nil
    }
}
