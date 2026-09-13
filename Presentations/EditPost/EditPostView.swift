//
//  EditPostView.swift
//  Instagram
//
//  Created by Kiro on 13/9/26.
//

import SwiftUI
import NukeUI

// MARK: - EditPostView

/// Instagram-style "Edit info" screen for a post. Presented as a sheet; provides
/// its own `NavigationStack` with Cancel/Done. Only caption + location are editable
/// (media is immutable).
struct EditPostView: View {

    @State private var viewModel: EditPostViewModel
    @State private var showDiscardConfirm = false

    init(viewModel: EditPostViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(L10n.EditPost.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.Common.cancel) { handleCancel() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.Common.save) { handleSave() }
                            .fontWeight(.semibold)
                            .disabled(!viewModel.canSave)
                    }
                }
                .confirmationDialog(
                    L10n.EditPost.discardTitle,
                    isPresented: $showDiscardConfirm,
                    titleVisibility: .visible
                ) {
                    Button(L10n.EditPost.discardConfirm, role: .destructive) {
                        AppRouter.shared.dismiss()
                    }
                    Button(L10n.EditPost.keepEditing, role: .cancel) {}
                }
                .task { await viewModel.loadPost() }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.post == nil {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.post == nil, let message = viewModel.errorMessage {
            ErrorStateView(
                message: message,
                retryAction: { Task { await viewModel.loadPost() } }
            )
        } else {
            editor
        }
    }

    // MARK: - Editor

    private var editor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                headerRow
                Divider()
                captionSection
                Divider()
                locationSection
            }
            .padding(.horizontal, DS.Padding.horizontal)
            .padding(.vertical, DS.Spacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Header (media thumbnail + author, read-only)

    private var headerRow: some View {
        HStack(spacing: DS.Spacing.sm) {
            mediaThumbnail

            Text(viewModel.authorUsername)
                .font(DS.Font.username)
                .foregroundStyle(ColorTokens.textPrimary)

            Spacer()
        }
    }

    @ViewBuilder
    private var mediaThumbnail: some View {
        Group {
            if let media = viewModel.previewMedia {
                LazyImage(url: media.thumbnailURL ?? media.url) { state in
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    } else {
                        Rectangle().fill(ColorTokens.backgroundSubtler)
                    }
                }
            } else {
                Rectangle().fill(ColorTokens.backgroundSubtler)
            }
        }
        .frame(width: DS.Size.avatarList, height: DS.Size.avatarList)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
    }

    // MARK: - Caption

    private var captionSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text(L10n.EditPost.caption)
                .font(DS.Font.subheadlineBold)
                .foregroundStyle(ColorTokens.textSecondary)

            TextField(
                L10n.EditPost.captionPlaceholder,
                text: $viewModel.caption,
                axis: .vertical
            )
            .font(DS.Font.subheadline)
            .lineLimit(4...10)

            HStack {
                Spacer()
                Text("\(viewModel.captionCharacterCount)/\(DS.Layout.maxCaptionLength)")
                    .font(DS.Font.caption)
                    .foregroundStyle(
                        viewModel.isCaptionValid
                            ? ColorTokens.textSecondary
                            : ColorTokens.destructive
                    )
            }
        }
    }

    // MARK: - Location

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text(L10n.EditPost.location)
                .font(DS.Font.subheadlineBold)
                .foregroundStyle(ColorTokens.textSecondary)

            TextField(
                L10n.EditPost.locationPlaceholder,
                text: $viewModel.locationName
            )
            .font(DS.Font.subheadline)
            .textFieldStyle(.plain)
        }
    }

    // MARK: - Actions

    private func handleSave() {
        Task {
            await viewModel.save()
            if viewModel.didSave {
                AppRouter.shared.dismiss()
            }
        }
    }

    private func handleCancel() {
        if viewModel.hasChanges {
            showDiscardConfirm = true
        } else {
            AppRouter.shared.dismiss()
        }
    }
}
