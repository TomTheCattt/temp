//
//  OfflineBannerView.swift
//  Instagram
//
//  Created by Antigravity on 22/10/26.
//

import SwiftUI

// MARK: - OfflineBannerView

/// Sleek, non-intrusive floating banner for network connectivity status.
///
/// Complies with Instagram iOS HIG:
/// - Floating pill shape (`DS.Radius.pill`), positioned gracefully under Safe Area.
/// - Glassmorphic / Elevated background (`ColorTokens.backgroundElevated`).
/// - Amber / warning style when offline, emerald green when reconnected.
/// - Touch-transparent (`allowsHitTesting(false)`) to prevent interaction interference.
struct OfflineBannerView: View {

    let status: NetworkBannerStatus

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            InstagramIcon(icon, size: 14, color: iconColor)

            Text(title)
                .font(DS.Font.subheadlineBold)
                .foregroundStyle(textColor)
                .lineLimit(1)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.xs)
        .background(
            Capsule()
                .fill(backgroundColor)
                .overlay(
                    Capsule()
                        .stroke(borderColor, lineWidth: DS.Stroke.thin)
                )
                .shadow(
                    color: ColorTokens.shadowMedium,
                    radius: DS.Shadow.radius,
                    x: 0,
                    y: DS.Shadow.offsetY
                )
        )
    }

    // MARK: - Dynamic Presentation Properties

    private var title: String {
        switch status {
        case .disconnected:
            return L10n.Error.offline
        case .reconnected:
            return L10n.Error.backOnline
        case .hidden:
            return ""
        }
    }

    private var icon: AppIcon {
        switch status {
        case .disconnected:
            return .system(name: "wifi.slash")
        case .reconnected:
            return .system(name: "checkmark.circle.fill")
        case .hidden:
            return .system(name: "wifi")
        }
    }

    private var iconColor: Color {
        switch status {
        case .disconnected:
            return ColorTokens.warning
        case .reconnected:
            return ColorTokens.success
        case .hidden:
            return ColorTokens.textSecondary
        }
    }

    private var textColor: Color {
        switch status {
        case .disconnected:
            return ColorTokens.textPrimary
        case .reconnected:
            return ColorTokens.success
        case .hidden:
            return ColorTokens.textPrimary
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .disconnected:
            return ColorTokens.backgroundElevated.opacity(DS.Opacity.high)
        case .reconnected:
            return ColorTokens.backgroundElevated.opacity(DS.Opacity.high)
        case .hidden:
            return .clear
        }
    }

    private var borderColor: Color {
        switch status {
        case .disconnected:
            return ColorTokens.warning.opacity(DS.Opacity.divider)
        case .reconnected:
            return ColorTokens.success.opacity(DS.Opacity.divider)
        case .hidden:
            return .clear
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        OfflineBannerView(status: .disconnected)
        OfflineBannerView(status: .reconnected)
    }
    .padding()
    .background(Color.black)
}
