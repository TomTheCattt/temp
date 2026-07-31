//
//  FeedVideoPlayer.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI
import AVKit
import Combine

// MARK: - FeedVideoPlayer

/// Video player for feed posts. Auto-plays when visible, pauses when scrolled away or app backgrounds.
/// Optimizations:
/// - Lazy: does not create/buffer video until visible
/// - Releases resources when scrolled off-screen
/// - Muted by default (saves audio decoding resources until user unmutes)
struct FeedVideoPlayer: View {

    let url: URL
    let id: String
    let isVisible: Bool

    @StateObject private var playerHolder = FeedPlayerHolder()
    @ObservedObject private var manager = VideoPlayerManager.shared
    @State private var isMuted = true

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VideoContentView(player: playerHolder.player)

            // Mute/unmute button
            Button {
                isMuted.toggle()
                playerHolder.player.isMuted = isMuted
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(DS.Font.caption)
                    .foregroundStyle(.white)
                    .padding(DS.Spacing.xs)
                    .background(
                        Circle().fill(Color.black.opacity(DS.Opacity.overlay))
                    )
            }
            .padding(DS.Spacing.sm)
        }
        .onAppear {
            if isVisible && manager.isPlaybackAllowed {
                playerHolder.activate(url: url, id: id, muted: isMuted)
            }
        }
        .onDisappear {
            playerHolder.deactivate(id: id)
        }
        .onChange(of: isVisible) { _, visible in
            if visible && manager.isPlaybackAllowed {
                playerHolder.activate(url: url, id: id, muted: isMuted)
            } else {
                playerHolder.deactivate(id: id)
            }
        }
        .onChange(of: manager.isPlaybackAllowed) { _, allowed in
            if allowed && isVisible {
                playerHolder.player.play()
            } else if !allowed {
                playerHolder.player.pause()
            }
        }
    }
}

// MARK: - FeedPlayerHolder

/// Manages a reusable AVPlayer for feed video posts.
/// - Muted by default to save audio decoding resources
/// - Loops playback (like Instagram feed videos)
/// - Releases item when not visible to free network buffers
final class FeedPlayerHolder: ObservableObject {

    let objectWillChange = ObservableObjectPublisher()

    let player = AVPlayer()
    private var loopObserver: Any?
    private var isActivated = false

    init() {
        player.automaticallyWaitsToMinimizeStalling = true
    }

    func activate(url: URL, id: String, muted: Bool) {
        guard !isActivated else { return }
        isActivated = true

        let item = AVPlayerItem(url: url)
        item.preferredForwardBufferDuration = 3.0 // Feed videos are smaller, less buffer needed
        player.replaceCurrentItem(with: item)
        player.isMuted = muted
        setupLooping()
        VideoPlayerManager.shared.register(player: player, for: id)
        player.play()
    }

    func deactivate(id: String) {
        guard isActivated else { return }
        isActivated = false

        player.pause()
        removeLoopObserver()
        VideoPlayerManager.shared.unregister(key: id)
        player.replaceCurrentItem(with: nil)
    }

    private func setupLooping() {
        removeLoopObserver()
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.player.seek(to: .zero)
            self?.player.play()
        }
    }

    private func removeLoopObserver() {
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
            loopObserver = nil
        }
    }

    deinit {
        removeLoopObserver()
        player.pause()
        player.replaceCurrentItem(with: nil)
    }
}
