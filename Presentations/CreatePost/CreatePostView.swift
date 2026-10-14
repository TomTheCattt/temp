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
    @State private var isShowingCamera = false
    @State private var isShowingCanvas = false
    @State private var isShowingLayout = false
    @State private var isShowingLocationPicker = false
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
            .fullScreenCover(isPresented: $isShowingCamera) {
                PostCameraView(isPresented: $isShowingCamera) { data, isVideo in
                    viewModel.setCapturedMedia(data: data, isVideo: isVideo)
                }
            }
            .fullScreenCover(isPresented: $isShowingCanvas) {
                CreateCanvasView(isPresented: $isShowingCanvas) { data in
                    viewModel.setCapturedMedia(data: data)
                }
            }
            .sheet(isPresented: $isShowingLayout) {
                LayoutCollageView(isPresented: $isShowingLayout) { data in
                    viewModel.setCapturedMedia(data: data)
                }
            }
            .sheet(isPresented: $isShowingLocationPicker) {
                LocationPickerSheet { loc in
                    viewModel.location = loc
                }
            }
        }
    }

    // MARK: - Navigation Title

    private var navigationTitle: String {
        switch viewModel.currentStep {
        case .selectMedia: return L10n.CreatePost.title
        case .applyFilter: return L10n.CreatePost.editStudio
        case .captionAndShare: return L10n.CreatePost.title
        }
    }

    // MARK: - Step 1: Media Selection & Camera Launch

    private var mediaSelectionStep: some View {
        VStack(spacing: DS.Spacing.md) {
            if viewModel.isLoadingMedia {
                ProgressView(L10n.Common.loading)
                    .frame(maxWidth: .infinity, minHeight: DS.Size.mediaPreviewMinHeight)
            } else if !viewModel.selectedImages.isEmpty {
                // Interactive Preview Canvas with Aspect Ratio Support
                let safeIndex = min(viewModel.activeImageIndex, viewModel.selectedImages.count - 1)
                let activeData = viewModel.selectedImages[safeIndex]

                if let uiImage = ImageDownsampler.shared.downsample(data: activeData, maxDimension: 1080) {
                    ZStack(alignment: .bottom) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(viewModel.aspectRatio.ratioValue, contentMode: .fit)
                            .clipped()
                            .background(Color.black)

                        // Floating Overlays: Aspect Ratio & Camera Shortcut
                        HStack {
                            // Aspect Ratio Toggle (1:1 / 4:5)
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.toggleAspectRatio()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "aspectratio")
                                    Text(viewModel.aspectRatio.rawValue)
                                }
                                .font(DS.Font.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, DS.Spacing.sm)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.6), in: Capsule())
                            }

                            Spacer()

                            // Camera Quick Button
                            Button {
                                isShowingCamera = true
                            } label: {
                                Image(systemName: "camera.fill")
                                    .font(DS.Font.subheadline)
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.6), in: Circle())
                            }
                        }
                        .padding(DS.Spacing.sm)
                    }
                }

                // Selected Images Carousel Strip (with Remove "X" buttons)
                if viewModel.selectedImages.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Spacing.sm) {
                            ForEach(0..<viewModel.selectedImages.count, id: \.self) { idx in
                                if let img = ImageDownsampler.shared.downsample(data: viewModel.selectedImages[idx], maxDimension: 200) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 56, height: 56)
                                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: DS.Radius.small)
                                                    .stroke(viewModel.activeImageIndex == idx ? ColorTokens.accentPrimary : Color.clear, lineWidth: 2.5)
                                            )
                                            .onTapGesture {
                                                viewModel.activeImageIndex = idx
                                            }

                                        // Badge Index
                                        Text("\(idx + 1)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(3)
                                            .background(ColorTokens.accentPrimary, in: Circle())
                                            .offset(x: -4, y: 4)

                                        // Remove Button
                                        Button {
                                            viewModel.removeImage(at: idx)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                                .foregroundStyle(.white, ColorTokens.destructive)
                                        }
                                        .offset(x: 4, y: -4)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DS.Padding.horizontal)
                        .padding(.vertical, DS.Spacing.xs)
                    }
                }
            } else {
                // Empty State: Action Tiles Hub
                VStack(spacing: DS.Spacing.lg) {
                    Spacer().frame(height: DS.Spacing.sm)

                    VStack(spacing: DS.Spacing.xs) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 56))
                            .foregroundStyle(ColorTokens.accentPrimary)
                        Text(L10n.CreatePost.title)
                            .font(DS.Font.headline)
                        Text("Bắt đầu bằng chụp ảnh mới hoặc chọn từ thư viện")
                            .font(DS.Font.caption)
                            .foregroundStyle(.secondary)
                    }

                    // 3 Creative Feature Tiles
                    HStack(spacing: DS.Spacing.md) {
                        // Camera Tile
                        tileButton(
                            icon: "camera.fill",
                            title: L10n.CreatePost.camera,
                            color: Color.blue
                        ) {
                            isShowingCamera = true
                        }

                        // Create (Aa) Canvas Tile
                        tileButton(
                            icon: "textformat",
                            title: L10n.CreatePost.createMode,
                            color: Color.purple
                        ) {
                            isShowingCanvas = true
                        }

                        // Layout Grid Tile
                        tileButton(
                            icon: "square.split.2x2",
                            title: L10n.CreatePost.layoutMode,
                            color: Color.orange
                        ) {
                            isShowingLayout = true
                        }
                    }
                    .padding(.horizontal, DS.Padding.horizontal)
                }
                .frame(maxWidth: .infinity, minHeight: DS.Size.mediaPreviewMinHeight)
            }

            Spacer()

            // Source Selector Actions
            VStack(spacing: DS.Spacing.sm) {
                // Action 1: Open Photo Library
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
                .onChange(of: viewModel.selectedItems) { _, _ in
                    Task { await viewModel.loadSelectedMedia() }
                }

                // Action 2: Open Camera
                Button {
                    isShowingCamera = true
                } label: {
                    Label(L10n.CreatePost.camera, systemImage: "camera")
                        .font(DS.Font.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.formGap)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: DS.Radius.input))
                }
            }
            .padding(.horizontal, DS.Padding.horizontal)
            .padding(.bottom, DS.Spacing.lg)
        }
    }

    // MARK: - Tile Button Helper

    @ViewBuilder
    private func tileButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: DS.Spacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(color, in: RoundedRectangle(cornerRadius: DS.Radius.medium))

                Text(title)
                    .font(DS.Font.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.sm)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: DS.Radius.medium))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 2: Universal Creative Studio (Filters, PIP Stickers, Typography)

    private var filterStep: some View {
        VStack(spacing: 0) {
            if !viewModel.selectedImages.isEmpty {
                let safeIndex = min(viewModel.activeImageIndex, viewModel.selectedImages.count - 1)
                UniversalCreativeStudioView(
                    baseImageData: Binding(
                        get: { viewModel.selectedImages[safeIndex] },
                        set: { _ in }
                    ),
                    selectedFilterId: $viewModel.selectedFilterId,
                    filterIntensity: $viewModel.filterIntensity,
                    onProceedToCaption: { bakedData in
                        viewModel.goToNextStep()
                    }
                )
            }

            // Multi-image thumbnail strip to switch active image
            if viewModel.selectedImages.count > 1 {
                Divider()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.xs) {
                        ForEach(0..<viewModel.selectedImages.count, id: \.self) { idx in
                            if let img = ImageDownsampler.shared.downsample(data: viewModel.selectedImages[idx], maxDimension: 120) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DS.Radius.small)
                                            .stroke(viewModel.activeImageIndex == idx ? ColorTokens.accentPrimary : Color.clear, lineWidth: 2.5)
                                    )
                                    .onTapGesture {
                                        viewModel.activeImageIndex = idx
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, DS.Padding.horizontal)
                    .padding(.vertical, DS.Spacing.xs)
                }
                .background(Color(.systemBackground))
            }
        }
    }

    // MARK: - Step 3: Caption, Audience, Details & Share

    private var captionStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                // Media Thumbnail + Caption TextEditor
                HStack(alignment: .top, spacing: DS.Spacing.sm) {
                    if let firstData = viewModel.selectedImages.first,
                       let uiImage = ImageDownsampler.shared.downsample(data: firstData, maxDimension: 240) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: DS.Size.avatarXLarge, height: DS.Size.avatarXLarge)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
                    }

                    TextField(L10n.CreatePost.captionPlaceholder, text: $viewModel.caption, axis: .vertical)
                        .font(DS.Font.subheadline)
                        .lineLimit(4...8)
                }
                .padding(.horizontal, DS.Padding.horizontal)

                Divider()

                // Location Picker & Active Location Chip
                if let loc = viewModel.location {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(ColorTokens.accentPrimary)
                        Text(loc.name)
                            .font(DS.Font.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Button {
                            viewModel.location = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, DS.Padding.horizontal)
                    .padding(.vertical, DS.Spacing.xs)
                } else {
                    Button {
                        isShowingLocationPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(.secondary)
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
                }

                Divider()

                // Tag People
                Button(action: {}) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .foregroundStyle(.secondary)
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

                // Audience Selector (Everyone / Close Friends)
                HStack {
                    Image(systemName: "person.2")
                        .foregroundStyle(.secondary)
                    Text(L10n.CreatePost.audience)
                        .font(DS.Font.subheadline)

                    Spacer()

                    Picker("", selection: $viewModel.isCloseFriendsOnly) {
                        Text(L10n.CreatePost.everyone).tag(false)
                        Text(L10n.CreatePost.closeFriends).tag(true)
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal, DS.Padding.horizontal)
                .padding(.vertical, DS.Spacing.xs)

                Divider()

                // Advanced Settings (Hide likes, Turn off comments)
                DisclosureGroup(L10n.CreatePost.advancedSettings) {
                    VStack(spacing: DS.Spacing.md) {
                        Toggle(L10n.CreatePost.hideLikes, isOn: $viewModel.hideLikes)
                            .font(DS.Font.caption)
                        Toggle(L10n.CreatePost.turnOffComments, isOn: $viewModel.disableComments)
                            .font(DS.Font.caption)
                    }
                    .padding(.top, DS.Spacing.xs)
                }
                .font(DS.Font.subheadlineBold)
                .padding(.horizontal, DS.Padding.horizontal)
                .padding(.vertical, DS.Spacing.xs)

                Divider()

                // Social Sharing Options
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text(L10n.CreatePost.alsoShareTo)
                        .font(DS.Font.subheadlineBold)
                        .padding(.horizontal, DS.Padding.horizontal)

                    shareToggleRow(title: "Facebook", isOn: .constant(false))
                    shareToggleRow(title: "Threads", isOn: .constant(false))
                }
                .padding(.top, DS.Spacing.xxs)
            }
            .padding(.top, DS.Spacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private func shareToggleRow(title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .font(DS.Font.subheadline)
            .padding(.horizontal, DS.Padding.horizontal)
    }
}
