//
//  ReelVideoPlayer.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI
import AVKit
import Combine

// MARK: - ReelVideoPlayer

/// A looping video player designed for Reels.
/// Optimizations:
/// - Player only starts buffering/playing when `isActive` is true
/// - Uses preloaded AVPlayerItem from VideoPlayerManager if available
/// - Releases player resources when deactivated
struct ReelVideoPlayer: View {

    let url: URL
    let id: String
    let isActive: Bool

    @StateObject private var playerHolder: ReelPlayerHolder
    @ObservedObject private var manager = VideoPlayerManager.shared

    init(url: URL, id: String, isActive: Bool) {
        self.url = url
        self.id = id
        self.isActive = isActive
        _playerHolder = StateObject(wrappedValue: ReelPlayerHolder())
    }

    var body: some View {
        VideoContentView(player: playerHolder.player)
            .onChange(of: isActive) { _, active in
                if active && manager.isPlaybackAllowed {
                    playerHolder.activate(url: url, id: id)
                } else {
                    playerHolder.deactivate(id: id)
                }
            }
            .onChange(of: manager.isPlaybackAllowed) { _, allowed in
                if allowed && isActive {
                    playerHolder.player.play()
                } else if !allowed {
                    playerHolder.player.pause()
                }
            }
            .onAppear {
                if isActive && manager.isPlaybackAllowed {
                    playerHolder.activate(url: url, id: id)
                }
            }
            .onDisappear {
                playerHolder.deactivate(id: id)
            }
    }
}

// MARK: - ReelPlayerHolder

/// Manages a single reusable AVPlayer for reel playback.
/// - Lazy: does not load video until `activate()` is called
/// - Reusable: swaps AVPlayerItem instead of creating new AVPlayer
/// - Looping: automatically seeks to start on completion
final class ReelPlayerHolder: ObservableObject {

    let objectWillChange = ObservableObjectPublisher()

    let player = AVPlayer()
    private var loopObserver: Any?
    private var isActivated = false

    init() {
        player.automaticallyWaitsToMinimizeStalling = true
    }

    /// Start playback for the given URL. Uses preloaded item if available.
    func activate(url: URL, id: String) {
        // If already active with the same content, just resume
        if isActivated {
            player.play()
            return
        }
        isActivated = true

        // Use preloaded item or create new one
        let item: AVPlayerItem
        if let preloaded = VideoPlayerManager.shared.consumePreloadedItem(for: id) {
            item = preloaded
        } else {
            item = AVPlayerItem(url: url)
            item.preferredForwardBufferDuration = 5.0
        }

        player.replaceCurrentItem(with: item)
        setupLooping()
        VideoPlayerManager.shared.register(player: player, for: id)
        player.play()
    }

    /// Stop playback and release the item to free memory.
    func deactivate(id: String) {
        guard isActivated else { return }
        isActivated = false

        player.pause()
        player.seek(to: .zero)
        removeLoopObserver()
        VideoPlayerManager.shared.unregister(key: id)
        // Release the item to free network buffers
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

// MARK: - VideoContentView

/// UIViewRepresentable that displays AVPlayer content with aspect-fill gravity.
struct VideoContentView: UIViewRepresentable {

    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        PlayerUIView(player: player)
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

// MARK: - PlayerUIView

final class PlayerUIView: UIView {

    let playerLayer: AVPlayerLayer

    init(player: AVPlayer) {
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        super.init(frame: .zero)
        layer.addSublayer(playerLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
