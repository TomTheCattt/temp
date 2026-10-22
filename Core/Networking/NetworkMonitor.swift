//
//  NetworkMonitor.swift
//  Instagram
//
//  Created by Kiro on 13/9/26.
//

import Foundation
import Network

// MARK: - NetworkBannerStatus

public enum NetworkBannerStatus: Sendable, Equatable {
    case hidden
    case disconnected
    case reconnected
}

// MARK: - NetworkMonitor

/// App-wide internet connectivity monitor built on `NWPathMonitor`.
///
/// - Observable singleton so any view can read `isConnected` and `bannerStatus`.
/// - Surfaces connectivity changes as a persistent, non-intrusive top banner:
///   goes offline → persistent offline banner; comes back online → reconnected banner (1.8s auto-dismiss).
/// - Safe task cancellation to prevent flapping / race conditions.
@MainActor
@Observable
final class NetworkMonitor {

    static let shared = NetworkMonitor()

    // MARK: - State

    /// Whether the device currently has a usable internet path.
    private(set) var isConnected = true

    /// Visual presentation status for the persistent top banner.
    private(set) var bannerStatus: NetworkBannerStatus = .hidden

    /// Tracks whether we've resolved the initial path yet.
    private var hasResolvedInitialState = false

    // MARK: - Private

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.instagram.networkmonitor")
    private var isStarted = false
    private var dismissBannerTask: Task<Void, Never>?

    private init() {}

    // MARK: - Lifecycle

    /// Start observing connectivity. Safe to call multiple times (no-op after first).
    func start() {
        guard !isStarted else { return }
        isStarted = true

        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = path.status == .satisfied
            Task { @MainActor [weak self] in
                self?.handlePathUpdate(isConnected: connected)
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        guard isStarted else { return }
        dismissBannerTask?.cancel()
        dismissBannerTask = nil
        monitor.cancel()
        isStarted = false
    }

    // MARK: - Handling

    private func handlePathUpdate(isConnected connected: Bool) {
        // First resolution at launch: record state, display if already offline.
        guard hasResolvedInitialState else {
            hasResolvedInitialState = true
            isConnected = connected
            if !connected {
                bannerStatus = .disconnected
            }
            return
        }

        // Ignore no-op updates (same status reported again).
        guard connected != isConnected else { return }
        isConnected = connected

        dismissBannerTask?.cancel()
        dismissBannerTask = nil

        if connected {
            if bannerStatus == .disconnected {
                bannerStatus = .reconnected
                dismissBannerTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 1_800_000_000)
                    guard !Task.isCancelled else { return }
                    self?.bannerStatus = .hidden
                }
            } else {
                bannerStatus = .hidden
            }
        } else {
            bannerStatus = .disconnected
        }
    }

    // MARK: - Testing Support

    #if DEBUG
    func simulateBannerStatusForTesting(_ status: NetworkBannerStatus) {
        bannerStatus = status
    }
    #endif
}
