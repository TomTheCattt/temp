//
//  VideoPlayerManager.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import AVFoundation
import Combine
import UIKit

// MARK: - VideoPlayerManager

/// Centralized manager for video playback lifecycle and resource management.
///
/// Performance optimizations:
/// - Limits concurrent AVPlayer instances to prevent memory pressure
/// - Preloads next video's AVPlayerItem for faster playback start
/// - Automatically pauses/resumes on app lifecycle transitions
/// - Provides player reuse via item swapping instead of creating new players
@MainActor
final class VideoPlayerManager: ObservableObject {

    static let shared = VideoPlayerManager()

    // MARK: - Configuration

    /// Maximum number of active AVPlayer instances allowed simultaneously.
    private let maxConcurrentPlayers = 3

    /// How many seconds of video to buffer ahead.
    private let preferredBufferDuration: TimeInterval = 5.0

    // MARK: - State

    /// All currently registered players (key → player).
    private var activePlayers: [String: AVPlayer] = [:]

    /// Order of registration for LRU eviction.
    private var registrationOrder: [String] = []

    /// Preloaded items ready for immediate playback.
    private var preloadedItems: [String: AVPlayerItem] = [:]

    /// Whether playback is allowed (false when app is in background).
    @Published private(set) var isPlaybackAllowed: Bool = true

    private var cancellables = Set<AnyCancellable>()

    private init() {
        observeAppLifecycle()
        configureAudioSession()
    }

    // MARK: - Player Registration

    /// Register a player with a unique key.
    /// Evicts the least-recently-used player if at capacity.
    func register(player: AVPlayer, for key: String) {
        // Already registered — just move to end of order
        if activePlayers[key] != nil {
            registrationOrder.removeAll { $0 == key }
            registrationOrder.append(key)
            return
        }

        // Evict oldest if at capacity
        while activePlayers.count >= maxConcurrentPlayers {
            evictOldest()
        }

        activePlayers[key] = player
        registrationOrder.append(key)
    }

    /// Unregister a player when it's no longer visible.
    func unregister(key: String) {
        activePlayers[key]?.pause()
        activePlayers[key]?.replaceCurrentItem(with: nil)
        activePlayers.removeValue(forKey: key)
        registrationOrder.removeAll { $0 == key }
    }

    /// Pause a specific player.
    func pause(key: String) {
        activePlayers[key]?.pause()
    }

    /// Play a specific player (only if playback is allowed).
    func play(key: String) {
        guard isPlaybackAllowed else { return }
        activePlayers[key]?.play()
    }

    /// Pause all active players.
    func pauseAll() {
        activePlayers.values.forEach { $0.pause() }
    }

    // MARK: - Preloading

    /// Preload a video URL so playback starts faster when needed.
    /// Only buffers the item; does not create an AVPlayer.
    func preload(url: URL, for key: String) {
        guard preloadedItems[key] == nil else { return }
        let item = AVPlayerItem(url: url)
        item.preferredForwardBufferDuration = preferredBufferDuration
        preloadedItems[key] = item
    }

    /// Retrieve a preloaded item (removes from cache).
    func consumePreloadedItem(for key: String) -> AVPlayerItem? {
        preloadedItems.removeValue(forKey: key)
    }

    /// Cancel preloading for a key.
    func cancelPreload(for key: String) {
        preloadedItems[key]?.cancelPendingSeeks()
        preloadedItems.removeValue(forKey: key)
    }

    /// Clear all preloaded items.
    func clearPreloads() {
        preloadedItems.removeAll()
    }

    // MARK: - Memory Pressure

    /// Called when system reports memory pressure. Aggressively free resources.
    func handleMemoryWarning() {
        // Keep only the currently playing player, evict the rest
        let playing = activePlayers.filter { $0.value.rate > 0 }
        let toEvict = activePlayers.keys.filter { playing[$0] == nil }
        toEvict.forEach { unregister(key: $0) }
        clearPreloads()
    }

    // MARK: - Private

    /// Evict the least-recently-used (oldest registered) player.
    private func evictOldest() {
        guard let oldestKey = registrationOrder.first else { return }
        unregister(key: oldestKey)
    }

    // MARK: - App Lifecycle

    private func observeAppLifecycle() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isPlaybackAllowed = false
                self?.pauseAll()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isPlaybackAllowed = true
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Non-fatal
        }
    }
}
