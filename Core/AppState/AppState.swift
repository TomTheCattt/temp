//
//  AppState.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI

// MARK: - AppState

/// Global, cross-cutting application state that drives root-level blocking overlays.
///
/// Observed by the root view (`RootContainerView`) to present full-screen,
/// app-wide screens that sit above everything else:
/// - `isUnderMaintenance` → `MaintenanceView` (backend returned HTTP 503)
/// - `forceUpdateRequired` → `ForceUpdateView` (backend returned HTTP 426)
///
/// Flags are set from `NetworkService` on the main actor when the corresponding
/// HTTP status is detected. Force-update takes precedence over maintenance when
/// both are active (see `RootContainerView`).
@MainActor
@Observable
final class AppState {

    static let shared = AppState()

    /// Backend is under maintenance (HTTP 503). Presents the maintenance screen.
    var isUnderMaintenance = false

    /// A mandatory app update is required (HTTP 426). Presents the force-update screen.
    var forceUpdateRequired = false

    private init() {}
}
