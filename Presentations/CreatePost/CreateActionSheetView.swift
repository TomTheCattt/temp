//
//  CreateActionSheetView.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import SwiftUI

// MARK: - CreateActionSheetView

/// Bottom Action Sheet presenting creation options (Post, Reel, Story, Live) matching Instagram iOS.
struct CreateActionSheetView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Drag Indicator
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, DS.Spacing.sm)
                .padding(.bottom, DS.Spacing.md)

            // Header Title
            Text(L10n.CreateMenu.title)
                .font(DS.Font.headline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.bottom, DS.Spacing.md)

            Divider()
                .opacity(DS.Opacity.divider)

            // Creation Options List
            VStack(spacing: 0) {
                // Option 1: Bài viết (Post)
                actionRow(
                    icon: .grid(selected: true),
                    title: L10n.CreateMenu.post
                ) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        AppRouter.shared.present(fullScreen: .creationHub(initialMode: .post))
                    }
                }

                Divider()
                    .padding(.leading, 56)
                    .opacity(DS.Opacity.divider)

                // Option 2: Thước phim (Reel)
                actionRow(
                    icon: .reels(selected: true),
                    title: L10n.CreateMenu.reel
                ) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        AppRouter.shared.present(fullScreen: .creationHub(initialMode: .reel))
                    }
                }

                Divider()
                    .padding(.leading, 56)
                    .opacity(DS.Opacity.divider)

                // Option 3: Tin (Story)
                actionRow(
                    icon: .camera,
                    title: L10n.CreateMenu.story
                ) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        AppRouter.shared.present(fullScreen: .creationHub(initialMode: .story))
                    }
                }

                Divider()
                    .padding(.leading, 56)
                    .opacity(DS.Opacity.divider)

                // Option 4: Phát trực tiếp (Live)
                actionRow(
                    icon: .system(name: "video.fill"),
                    title: L10n.CreateMenu.live
                ) {
                    dismiss()
                    HUDManager.shared.showInfo(L10n.CreateMenu.liveNotAvailable)
                }
            }

            Spacer()
        }
        .presentationDetents([.height(310)])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Action Row

    @ViewBuilder
    private func actionRow(icon: AppIcon, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.md) {
                InstagramIcon(icon, size: 22, color: .primary)
                    .frame(width: 28, height: 28)

                Text(title)
                    .font(DS.Font.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Spacer()

                InstagramIcon(.chevronRight, size: DS.Size.iconSmall, color: .secondary)
            }
            .padding(.horizontal, DS.Padding.horizontal)
            .padding(.vertical, DS.Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
