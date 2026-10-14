//
//  NetworkMonitor.swift
//  Instagram
//
//  Created by Kiro on 13/9/26.
//

import Foundation
import Network

// MARK: - NetworkMonitor

/// App-wide internet connectivity monitor built on `NWPathMonitor`.
///
/// - Observable singleton so any view can read `isConnected`.
/// - Surfaces connectivity changes as minimal toasts (not popups):
///   goes offline → warning toast; comes back online → success toast.
/// - Only reacts to *transitions* (avoids spamming), and stays silent on the
///   very first status resolved at launch.
@MainActor
@Observable
final class NetworkMonitor {

    static let shared = NetworkMonitor()

    // MARK: - State

    /// Whether the device currently has a usable internet path.
    private(set) var isConnected = true

    /// Tracks whether we've resolved the initial path yet (to stay silent on launch).
    private var hasResolvedInitialState = false

    // MARK: - Private

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.instagram.networkmonitor")
    private var isStarted = false

    private init() {}

    // MARK: - Lifecycle

    /// Start observing connectivity. Safe to call multiple times (no-op after first).
    func start() {
        guard !isStarted else { return }
        isStarted = true

        monitor.pathUpdateHandler = { path in
            let connected = path.status == .satisfied
            Task { @MainActor [weak self = self] in
                self?.handlePathUpdate(isConnected: connected)
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        guard isStarted else { return }
        monitor.cancel()
        isStarted = false
    }

    // MARK: - Handling

    private func handlePathUpdate(isConnected connected: Bool) {
        // First resolution at launch: record state, notify only if already offline.
        guard hasResolvedInitialState else {
            hasResolvedInitialState = true
            isConnected = connected
            if !connected {
                ToastManager.shared.warning(L10n.Error.offline)
            }
            return
        }

        // Ignore no-op updates (same status reported again).
        guard connected != isConnected else { return }
        isConnected = connected

        if connected {
            ToastManager.shared.success(L10n.Error.backOnline)
        } else {
            ToastManager.shared.warning(L10n.Error.offline)
        }
    }
}
