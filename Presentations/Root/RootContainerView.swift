//
//  RootContainerView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI

// MARK: - RootContainerView

/// Top-level view-hierarchy container that hosts the launch flow (`SplashView`)
/// and observes global `AppState` to present app-wide blocking overlays.
///
/// Overlay precedence (highest first):
/// 1. `ForceUpdateView`  — mandatory update (HTTP 426), non-dismissible.
/// 2. `MaintenanceView`  — backend maintenance (HTTP 503).
///
/// This exists because `App` structs can't cleanly hold observable `@State`;
/// the observation lives here instead. Rendered by `InstagramApp`.
struct RootContainerView: View {

    @State private var appState = AppState.shared

    var body: some View {
        SplashView()
            .overlay {
                overlayContent
            }
    }

    @ViewBuilder
    private var overlayContent: some View {
        if appState.forceUpdateRequired {
            // Force-update takes precedence over maintenance when both are active.
            ForceUpdateView()
                .transition(.opacity)
        } else if appState.isUnderMaintenance {
            MaintenanceView()
                .transition(.opacity)
        }
    }
}

#Preview {
    RootContainerView()
}
