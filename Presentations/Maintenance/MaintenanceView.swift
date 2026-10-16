//
//  MaintenanceView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI

// MARK: - MaintenanceView

/// Full-screen, friendly blocking screen shown while the backend is under
/// maintenance (HTTP 503). Presented at the root by `RootContainerView`
/// when `AppState.shared.isUnderMaintenance` is `true`.
///
/// The "Try again" button clears the flag so the next request can re-detect
/// whether maintenance is still ongoing.
struct MaintenanceView: View {

    @State private var appState = AppState.shared

    var body: some View {
        ZStack {
            ColorTokens.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: DS.Spacing.xl) {

                InstagramIcon(.system(name: "wrench.and.screwdriver.fill"), size: DS.Size.iconJumbo, color: ColorTokens.warning)

                VStack(spacing: DS.Spacing.sm) {
                    Text(L10n.Maintenance.title)
                        .font(DS.Font.largeTitle)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(L10n.Maintenance.message)
                        .font(DS.Font.body)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .multilineTextAlignment(.center)
                }

                tryAgainButton
                    .padding(.top, DS.Spacing.sm)
            }
            .padding(.horizontal, DS.Spacing.xl)
        }
    }

    private var tryAgainButton: some View {
        Button {
            // Clear the flag so the next network request can re-detect maintenance.
            appState.isUnderMaintenance = false
        } label: {
            Text(L10n.Maintenance.tryAgain)
                .font(DS.Font.headline)
                .frame(maxWidth: .infinity)
                .frame(height: DS.Size.buttonDefaultHeight)
                .foregroundStyle(ColorTokens.textInverted)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.pill, style: .continuous)
                        .fill(ColorTokens.accentPrimary)
                )
        }
    }
}

#Preview("Light") {
    MaintenanceView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    MaintenanceView()
        .preferredColorScheme(.dark)
}
