//
//  OfflineBannerModifier.swift
//  Instagram
//
//  Created by Antigravity on 22/10/26.
//

import SwiftUI

// MARK: - OfflineBannerModifier

/// ViewModifier that presents the persistent top offline banner driven by `NetworkMonitor.shared`.
struct OfflineBannerModifier: ViewModifier {

    @State private var networkMonitor = NetworkMonitor.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if networkMonitor.bannerStatus != .hidden {
                    OfflineBannerView(status: networkMonitor.bannerStatus)
                        .padding(.horizontal, DS.Spacing.md)
                        .safeAreaPadding(.top)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .allowsHitTesting(false)
                        .zIndex(1000)
                }
            }
            .animation(DS.Animation.gentleSpring, value: networkMonitor.bannerStatus)
            .onChange(of: networkMonitor.bannerStatus) { _, newStatus in
                switch newStatus {
                case .disconnected:
                    HapticFeedbackSafe.notification(.warning)
                case .reconnected:
                    HapticFeedbackSafe.notification(.success)
                case .hidden:
                    break
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Overlays the persistent Instagram-style top connectivity banner.
    func withOfflineBanner() -> some View {
        modifier(OfflineBannerModifier())
    }
}
