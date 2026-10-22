//
//  ChatAudioPlayer.swift
//  Instagram
//
//  Created by Antigravity on 22/10/26.
//

import Foundation
import AVFoundation
import Combine

// MARK: - ChatAudioPlayer

/// Centralized audio player managing voice message playback in chat.
/// Guarantees that only ONE audio message plays at any given moment.
@MainActor
public final class ChatAudioPlayer: ObservableObject {

    public static let shared = ChatAudioPlayer()

    @Published public private(set) var currentPlayingURL: URL?
    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var playbackProgress: Double = 0.0
    @Published public private(set) var currentTime: TimeInterval = 0.0
    @Published public private(set) var duration: TimeInterval = 0.0

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var endObserverToken: AnyCancellable?

    private init() {}

    isolated deinit {
        removeTimeObserver()
    }

    // MARK: - Public Control API

    /// Toggle Play/Pause for a given audio message URL.
    public func togglePlayPause(url: URL, expectedDuration: TimeInterval = 0) {
        if currentPlayingURL == url {
            if isPlaying {
                pause()
            } else {
                resume()
            }
        } else {
            play(url: url, fallbackDuration: expectedDuration)
        }
    }

    public func play(url: URL, fallbackDuration: TimeInterval = 0) {
        // Stop any currently playing audio
        stop()

        guard !CallManager.shared.hasActiveCall else {
            return
        }

        // Configure playback audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[ChatAudioPlayer] Failed to activate audio session: \(error)")
        }

        currentPlayingURL = url
        duration = fallbackDuration > 0 ? fallbackDuration : 1.0

        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        self.player = newPlayer

        // Listen for playback end
        endObserverToken = NotificationCenter.default.publisher(
            for: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            self?.handlePlaybackFinished()
        }

        // Setup smooth progress periodic observer (20 FPS update)
        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserverToken = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            let currentSec = CMTimeGetSeconds(time)
            guard currentSec.isFinite else { return }
            Task { @MainActor [weak self] in
                self?.updatePlaybackProgress(currentSec: currentSec)
            }
        }

        // Load asset duration asynchronously if fallback was 0
        Task { [weak self] in
            if let assetDuration = try? await playerItem.asset.load(.duration) {
                let sec = CMTimeGetSeconds(assetDuration)
                if sec.isFinite && sec > 0 {
                    await MainActor.run {
                        self?.duration = sec
                    }
                }
            }
        }

        newPlayer.play()
        isPlaying = true
    }

    public func pause() {
        player?.pause()
        isPlaying = false
    }

    public func resume() {
        guard let p = player else { return }
        p.play()
        isPlaying = true
    }

    public func stop() {
        player?.pause()
        removeTimeObserver()
        endObserverToken?.cancel()
        endObserverToken = nil
        player = nil
        currentPlayingURL = nil
        isPlaying = false
        playbackProgress = 0.0
        currentTime = 0.0
        duration = 0.0
    }

    public func seek(to progress: Double) {
        guard let p = player, duration > 0 else { return }
        let clamped = min(max(progress, 0.0), 1.0)
        let targetSec = clamped * duration
        let targetTime = CMTime(seconds: targetSec, preferredTimescale: 600)
        p.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        playbackProgress = clamped
        currentTime = targetSec
    }

    // MARK: - Private Helpers

    private func updatePlaybackProgress(currentSec: Double) {
        currentTime = currentSec
        let total = duration > 0 ? duration : 1.0
        playbackProgress = min(max(currentSec / total, 0.0), 1.0)
    }

    private func handlePlaybackFinished() {
        stop()
    }

    private func removeTimeObserver() {
        if let token = timeObserverToken, let p = player {
            p.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
}
