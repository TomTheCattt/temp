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
                    icon: "square.stack.fill",
                    title: L10n.CreateMenu.post
                ) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        AppRouter.shared.present(fullScreen: .createPost)
                    }
                }

                Divider()
                    .padding(.leading, 56)
                    .opacity(DS.Opacity.divider)

                // Option 2: Thước phim (Reel)
                actionRow(
                    icon: "play.square.fill",
                    title: L10n.CreateMenu.reel
                ) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        AppRouter.shared.present(fullScreen: .createReel)
                    }
                }

                Divider()
                    .padding(.leading, 56)
                    .opacity(DS.Opacity.divider)

                // Option 3: Tin (Story)
                actionRow(
                    icon: "plus.circle.fill",
                    title: L10n.CreateMenu.story
                ) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        AppRouter.shared.present(fullScreen: .createStory)
                    }
                }

                Divider()
                    .padding(.leading, 56)
                    .opacity(DS.Opacity.divider)

                // Option 4: Phát trực tiếp (Live)
                actionRow(
                    icon: "video.fill",
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
    private func actionRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.primary)

                Text(title)
                    .font(DS.Font.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DS.Padding.horizontal)
            .padding(.vertical, DS.Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
