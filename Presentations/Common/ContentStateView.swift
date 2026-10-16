//
//  ContentStateView.swift
//  Instagram
//
//  Created by Kiro on 13/9/26.
//

import SwiftUI

// MARK: - ErrorStateView

/// Reusable full-area error state for data-fetch screens.
/// Shows a friendly message (never a raw technical error) and an optional retry button.
struct ErrorStateView: View {

    let message: String
    var icon: AppIcon
    var retryAction: (() -> Void)?

    init(
        message: String,
        icon: AppIcon = .system(name: "exclamationmark.triangle"),
        retryAction: (() -> Void)? = nil
    ) {
        self.message = message
        self.icon = icon
        self.retryAction = retryAction
    }

    init(
        message: String,
        systemImage: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.message = message
        self.icon = .system(name: systemImage)
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            InstagramIcon(icon, size: DS.Size.iconJumbo, color: ColorTokens.textSecondary)

            Text(message)
                .font(DS.Font.subheadline)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)

            if let retryAction {
                Button(action: retryAction) {
                    Text(L10n.Common.retry)
                        .font(DS.Font.username)
                }
                .tint(ColorTokens.accentPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DS.Padding.content)
        .padding(.vertical, DS.Spacing.xxxl)
    }
}

// MARK: - EmptyStateView

/// Reusable full-area empty state for data-fetch screens with no content.
struct EmptyStateView: View {

    let message: String
    var icon: AppIcon
    var title: String?

    init(message: String, icon: AppIcon = .system(name: "tray"), title: String? = nil) {
        self.message = message
        self.icon = icon
        self.title = title
    }

    init(message: String, systemImage: String, title: String? = nil) {
        self.message = message
        self.icon = .system(name: systemImage)
        self.title = title
    }

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            InstagramIcon(icon, size: DS.Size.iconJumbo, color: ColorTokens.textSecondary)

            if let title {
                Text(title)
                    .font(DS.Font.headline)
                    .foregroundStyle(ColorTokens.textPrimary)
            }

            Text(message)
                .font(DS.Font.subheadline)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DS.Padding.content)
        .padding(.vertical, DS.Spacing.xxxl)
    }
}
