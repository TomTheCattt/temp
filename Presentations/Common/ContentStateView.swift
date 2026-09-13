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
    var systemImage: String = "exclamationmark.triangle"
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(ColorTokens.textSecondary)

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
    var systemImage: String = "tray"
    var title: String?

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(ColorTokens.textSecondary)

            if let title {
                Text(title)
                    .font(DS.Font.username)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .multilineTextAlignment(.center)
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
