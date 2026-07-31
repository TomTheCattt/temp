//
//  CreatePostView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import PhotosUI

// MARK: - CreatePostView

struct CreatePostView: View {

    @State private var viewModel: CreatePostViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: CreatePostViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                switch viewModel.currentStep {
                case .selectMedia:
                    mediaSelectionStep
                case .applyFilter:
                    filterStep
                case .captionAndShare:
                    captionStep
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel.currentStep == .selectMedia {
                        Button(L10n.Common.cancel) { dismiss() }
                    } else {
                        Button(action: { viewModel.goToPreviousStep() }) {
                            Image(systemName: "chevron.left")
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.currentStep == .captionAndShare {
                        Button(L10n.Common.share) {
                            Task {
                                await viewModel.publish()
                                if viewModel.isPublished {
                                    dismiss()
                                }
                            }
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorTokens.accentPrimary)
                        .disabled(!viewModel.canPublish)
                    } else {
                        Button(L10n.Common.next) {
                            viewModel.goToNextStep()
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorTokens.accentPrimary)
                        .disabled(!viewModel.canProceedFromMedia)
                    }
                }
            }
            .alert(L10n.Common.error, isPresented: .init(
                get: { viewModel.publishError != nil },
                set: { if !$0 { viewModel.publishError = nil } }
            )) {
                Button(L10n.Common.ok) {}
            } message: {
                Text(viewModel.publishError ?? "")
            }
        }
    }

    // MARK: - Navigation Title

    private var navigationTitle: String {
        switch viewModel.currentStep {
        case .selectMedia: return L10n.CreatePost.title
        case .applyFilter: return L10n.CreatePost.filter
        case .captionAndShare: return L10n.CreatePost.title
        }
    }

    // MARK: - Step 1: Media Selection

    private var mediaSelectionStep: some View {
        VStack(spacing: DS.Spacing.md) {
            // Preview area
            if viewModel.isLoadingMedia {
                ProgressView(L10n.Common.loading)
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if !viewModel.selectedImages.isEmpty {
                if let firstData = viewModel.selectedImages.first,
                   let uiImage = UIImage(data: firstData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 350)
                        .clipped()
                }

                if viewModel.mediaCount > 1 {
                    Text(L10n.CreatePost.itemsSelected(viewModel.mediaCount))
                        .font(DS.Font.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: DS.Size.iconHero))
                        .foregroundStyle(.secondary)
                    Text(L10n.CreatePost.selectMedia)
                        .font(DS.Font.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 300)
            }

            Spacer()

            // Photo picker
            PhotosPicker(
                selection: $viewModel.selectedItems,
                maxSelectionCount: DS.Layout.maxPostMedia,
                matching: .any(of: [.images, .videos])
            ) {
                Label(L10n.CreatePost.selectFromLibrary, systemImage: "photo.stack")
                    .font(DS.Font.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.formGap)
                    .background(ColorTokens.buttonPrimary, in: RoundedRectangle(cornerRadius: DS.Radius.input))
            }
            .padding(.horizontal, DS.Padding.horizontal)
            .onChange(of: viewModel.selectedItems) { _, _ in
                Task { await viewModel.loadSelectedMedia() }
            }

            Spacer().frame(height: DS.Spacing.lg)
        }
    }

    // MARK: - Step 2: Filter

    private var filterStep: some View {
        VStack(spacing: 0) {
            if let firstData = viewModel.selectedImages.first,
               let uiImage = UIImage(data: firstData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 400)
                    .clipped()
            }

            Divider()

            // Filter strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.sm) {
                    filterThumbnail(name: "Normal", id: nil)
                    filterThumbnail(name: "Clarendon", id: "clarendon")
                    filterThumbnail(name: "Gingham", id: "gingham")
                    filterThumbnail(name: "Moon", id: "moon")
                    filterThumbnail(name: "Lark", id: "lark")
                    filterThumbnail(name: "Reyes", id: "reyes")
                    filterThumbnail(name: "Juno", id: "juno")
                    filterThumbnail(name: "Slumber", id: "slumber")
                    filterThumbnail(name: "Crema", id: "crema")
                    filterThumbnail(name: "Ludwig", id: "ludwig")
                    filterThumbnail(name: "Aden", id: "aden")
                    filterThumbnail(name: "Perpetua", id: "perpetua")
                }
                .padding(.horizontal, DS.Padding.horizontal)
                .padding(.vertical, DS.Spacing.sm)
            }
        }
    }

    @ViewBuilder
    private func filterThumbnail(name: String, id: String?) -> some View {
        let isSelected = viewModel.selectedFilterId == id

        VStack(spacing: DS.Spacing.xxs) {
            RoundedRectangle(cornerRadius: DS.Radius.small)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 72, height: 72)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.small)
                        .stroke(isSelected ? ColorTokens.accentPrimary : Color.clear, lineWidth: DS.Stroke.medium)
                )

            Text(name)
                .font(DS.Font.caption2)
                .foregroundStyle(isSelected ? ColorTokens.accentPrimary : .primary)
        }
        .onTapGesture {
            viewModel.selectedFilterId = id
        }
    }

    // MARK: - Step 3: Caption & Share

    private var captionStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                // Preview + caption
                HStack(alignment: .top, spacing: DS.Spacing.sm) {
                    if let firstData = viewModel.selectedImages.first,
                       let uiImage = UIImage(data: firstData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: DS.Size.avatarXLarge, height: DS.Size.avatarXLarge)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
                    }

                    TextField(L10n.CreatePost.captionPlaceholder, text: $viewModel.caption, axis: .vertical)
                        .font(DS.Font.subheadline)
                        .lineLimit(5...10)
                }
                .padding(.horizontal, DS.Padding.horizontal)

                Divider()

                // Location
                Button(action: {}) {
                    HStack {
                        Text(L10n.CreatePost.addLocation)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(DS.Font.caption)
                            .foregroundStyle(.secondary)
                    }
                    .font(DS.Font.subheadline)
                    .padding(.horizontal, DS.Padding.horizontal)
                    .padding(.vertical, DS.Spacing.sm)
                }

                Divider()

                // Tag people
                Button(action: {}) {
                    HStack {
                        Text(L10n.CreatePost.tagPeople)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(DS.Font.caption)
                            .foregroundStyle(.secondary)
                    }
                    .font(DS.Font.subheadline)
                    .padding(.horizontal, DS.Padding.horizontal)
                    .padding(.vertical, DS.Spacing.sm)
                }

                Divider()

                // Share options
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text(L10n.CreatePost.alsoShareTo)
                        .font(DS.Font.subheadlineBold)
                        .padding(.horizontal, DS.Padding.horizontal)

                    shareToggleRow(title: "Facebook", isOn: .constant(false))
                    shareToggleRow(title: "Twitter", isOn: .constant(false))
                }
                .padding(.top, DS.Spacing.xxs)
            }
            .padding(.top, DS.Spacing.md)
        }
    }

    @ViewBuilder
    private func shareToggleRow(title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .font(DS.Font.subheadline)
            .padding(.horizontal, DS.Padding.horizontal)
    }
}
