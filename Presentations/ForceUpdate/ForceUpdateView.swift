//
//  ForceUpdateView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI

// MARK: - ForceUpdateView

/// Full-screen, non-dismissible blocking screen shown when a mandatory app
/// update is required (HTTP 426). Presented at the root by `RootContainerView`
/// when `AppState.shared.forceUpdateRequired` is `true`, and takes precedence
/// over the maintenance screen.
///
/// There is intentionally no dismiss path — the only action is "Update now",
/// which opens the App Store product page.
struct ForceUpdateView: View {

    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            ColorTokens.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: DS.Spacing.xl) {

                InstagramIcon(.system(name: "arrow.down.circle.fill"), size: DS.Size.iconJumbo, color: ColorTokens.accentPrimary)

                VStack(spacing: DS.Spacing.sm) {
                    Text(L10n.ForceUpdate.title)
                        .font(DS.Font.largeTitle)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(L10n.ForceUpdate.message)
                        .font(DS.Font.body)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .multilineTextAlignment(.center)
                }

                updateButton
                    .padding(.top, DS.Spacing.sm)
            }
            .padding(.horizontal, DS.Spacing.xl)
        }
        .interactiveDismissDisabled(true)
    }

    private var updateButton: some View {
        Button {
            if let url = AppConfig.shared.appStoreURL {
                openURL(url)
            }
        } label: {
            Text(L10n.ForceUpdate.updateNow)
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
    ForceUpdateView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ForceUpdateView()
        .preferredColorScheme(.dark)
}
