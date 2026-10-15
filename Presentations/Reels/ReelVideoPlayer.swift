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
/// - Displays dark skeleton placeholder until video item is ready to play
/// - Releases player resources when deactivated
struct ReelVideoPlayer: View {

    let url: URL
    let fallbackURL: URL?
    let id: String
    let isActive: Bool

    @StateObject private var playerHolder: ReelPlayerHolder
    @ObservedObject private var manager = VideoPlayerManager.shared

    init(url: URL, fallbackURL: URL? = nil, id: String, isActive: Bool) {
        self.url = url
        self.fallbackURL = fallbackURL
        self.id = id
        self.isActive = isActive
        _playerHolder = StateObject(wrappedValue: ReelPlayerHolder())
    }

    var body: some View {
        VideoContentView(player: playerHolder.player)
            .onChange(of: isActive) { _, active in
                if active && manager.isPlaybackAllowed {
                    playerHolder.activate(url: url, fallbackURL: fallbackURL, id: id)
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
                    playerHolder.activate(url: url, fallbackURL: fallbackURL, id: id)
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
/// - Fallback Safe: falls back to stable video URL if stream fails
final class ReelPlayerHolder: ObservableObject {

    let objectWillChange = ObservableObjectPublisher()

    let player = AVPlayer()
    private var loopObserver: Any?
    private var failedObserver: Any?
    private var isActivated = false
    private var fallbackAttempted = false
    private var currentFallbackURL: URL?
    private var statusCancellable: AnyCancellable?

    init() {
        player.automaticallyWaitsToMinimizeStalling = true
    }

    /// Start playback for the given URL. Uses preloaded item if available.
    func activate(url: URL, fallbackURL: URL? = nil, id: String) {
        // If already active with the same content, just resume
        if isActivated {
            player.play()
            return
        }
        isActivated = true
        fallbackAttempted = false
        currentFallbackURL = fallbackURL

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
        setupFailureObserver()
        VideoPlayerManager.shared.register(player: player, for: id)
        player.play()
    }

    private func triggerFallback() {
        guard !fallbackAttempted, let fallback = currentFallbackURL else { return }
        fallbackAttempted = true
        let fallbackItem = AVPlayerItem(url: fallback)
        fallbackItem.preferredForwardBufferDuration = 5.0
        player.replaceCurrentItem(with: fallbackItem)
        setupLooping()
        player.play()
    }

    /// Stop playback and release the item to free memory.
    func deactivate(id: String) {
        guard isActivated else { return }
        isActivated = false
        fallbackAttempted = false
        currentFallbackURL = nil

        player.pause()
        player.seek(to: .zero)
        removeLoopObserver()
        removeFailureObserver()
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

    private func setupFailureObserver() {
        removeFailureObserver()
        guard let currentItem = player.currentItem else { return }

        failedObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.triggerFallback()
        }

        statusCancellable = currentItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .failed {
                    self?.triggerFallback()
                }
            }
    }

    private func removeLoopObserver() {
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
            loopObserver = nil
        }
    }

    private func removeFailureObserver() {
        if let observer = failedObserver {
            NotificationCenter.default.removeObserver(observer)
            failedObserver = nil
        }
        statusCancellable?.cancel()
        statusCancellable = nil
    }

    deinit {
        removeLoopObserver()
        removeFailureObserver()
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
        playerLayer.backgroundColor = UIColor.clear.cgColor
        super.init(frame: .zero)
        backgroundColor = .clear
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
