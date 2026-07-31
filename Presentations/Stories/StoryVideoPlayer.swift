//
//  StoryVideoPlayer.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI
import AVKit
import Combine

// MARK: - StoryVideoPlayer

/// Video player for Story items. Integrates with VideoPlayerManager for background pause/resume.
/// Reports playback progress back to the parent via a callback so the progress bar stays in sync.
/// Optimizations:
/// - Single reusable AVPlayer instance (swaps items)
/// - Async duration loading (iOS 16+ API)
/// - Releases item on deactivation
struct StoryVideoPlayer: View {

    let url: URL
    let id: String
    let isActive: Bool
    let isPaused: Bool
    var onProgressUpdate: ((Double) -> Void)?
    var onVideoEnded: (() -> Void)?

    @StateObject private var playerHolder = StoryPlayerHolder()
    @ObservedObject private var manager = VideoPlayerManager.shared

    var body: some View {
        VideoContentView(player: playerHolder.player)
            .onAppear {
                playerHolder.onProgressUpdate = onProgressUpdate
                playerHolder.onVideoEnded = onVideoEnded
                if isActive && !isPaused && manager.isPlaybackAllowed {
                    playerHolder.activate(url: url, id: id)
                }
            }
            .onDisappear {
                playerHolder.deactivate(id: id)
            }
            .onChange(of: isActive) { _, active in
                playerHolder.onProgressUpdate = onProgressUpdate
                playerHolder.onVideoEnded = onVideoEnded
                if active && !isPaused && manager.isPlaybackAllowed {
                    playerHolder.activate(url: url, id: id)
                } else {
                    playerHolder.deactivate(id: id)
                }
            }
            .onChange(of: isPaused) { _, paused in
                if paused {
                    playerHolder.player.pause()
                } else if isActive && manager.isPlaybackAllowed {
                    playerHolder.player.play()
                }
            }
            .onChange(of: manager.isPlaybackAllowed) { _, allowed in
                if allowed && isActive && !isPaused {
                    playerHolder.player.play()
                } else if !allowed {
                    playerHolder.player.pause()
                }
            }
    }
}

// MARK: - StoryPlayerHolder

/// Manages AVPlayer lifecycle for a single story video item.
/// - No looping: stories auto-advance on completion
/// - Tracks progress via periodic time observer
/// - Loads duration asynchronously (iOS 16+)
final class StoryPlayerHolder: ObservableObject {

    let objectWillChange = ObservableObjectPublisher()

    let player = AVPlayer()
    var onProgressUpdate: ((Double) -> Void)?
    var onVideoEnded: (() -> Void)?

    private var timeObserver: Any?
    private var endObserver: Any?
    private var duration: Double = 0
    private var isActivated = false

    init() {
        player.automaticallyWaitsToMinimizeStalling = true
    }

    func activate(url: URL, id: String) {
        guard !isActivated else { return }
        isActivated = true
        duration = 0

        let item = AVPlayerItem(url: url)
        item.preferredForwardBufferDuration = 5.0
        player.replaceCurrentItem(with: item)

        setupEndObserver()
        startProgressTracking()
        VideoPlayerManager.shared.register(player: player, for: id)
        player.play()

        // Load duration asynchronously
        Task {
            if let dur = try? await item.asset.load(.duration) {
                let seconds = CMTimeGetSeconds(dur)
                if seconds.isFinite && seconds > 0 {
                    self.duration = seconds
                }
            }
        }
    }

    func deactivate(id: String) {
        guard isActivated else { return }
        isActivated = false

        player.pause()
        stopProgressTracking()
        removeEndObserver()
        VideoPlayerManager.shared.unregister(key: id)
        player.replaceCurrentItem(with: nil)
    }

    // MARK: - Progress Tracking

    private func startProgressTracking() {
        stopProgressTracking()

        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self, self.duration > 0 else { return }
            let current = CMTimeGetSeconds(time)
            let progress = min(current / self.duration, 1.0)
            self.onProgressUpdate?(progress)
        }
    }

    private func stopProgressTracking() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    // MARK: - End Observer

    private func setupEndObserver() {
        removeEndObserver()
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.onVideoEnded?()
        }
    }

    private func removeEndObserver() {
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
    }

    deinit {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        player.pause()
        player.replaceCurrentItem(with: nil)
    }
}
