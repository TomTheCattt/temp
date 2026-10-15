//
//  CreatePostView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import Photos
import PhotosUI

// MARK: - CreatePostView

/// Modern Post Creation View matching the original app reference:
/// 1. Screen 1: 50/50 Split View (Top Media Preview + Middle Bar + Bottom Native Camera Roll Grid).
/// 2. Screen 2: Immersive Dark Studio (Top Audio Selector Pill, Center Rounded Media Carousel with Delete, Middle 6-Tool Quickbar, Bottom Thumbnail Strip with Add & Next Button).
/// 3. Screen 3: Share Details (Caption, Tags, Music, Location, Privacy & Publish).
struct CreatePostView: View {

    // MARK: - Constants

    private enum Constants {
        // Top Header
        static let closeButtonSize: CGFloat = 36
        static let closeIconSize: CGFloat = 14
        static let audioPillHeight: CGFloat = 42
        static let audioCoverSize: CGFloat = 28
        static let audioCoverRadius: CGFloat = 4
        static let audioTitleFontSize: CGFloat = 12
        static let audioSubtitleFontSize: CGFloat = 10
        static let audioBadgeFontSize: CGFloat = 8
        static let audioPlusButtonSize: CGFloat = 24
        static let audioPlusIconSize: CGFloat = 10

        // Media Preview Card
        static let mediaCardRadius: CGFloat = 16
        static let mediaCardMaxHeight: CGFloat = 460
        static let deleteButtonSize: CGFloat = 28
        static let deleteIconSize: CGFloat = 12
        static let deleteButtonInset: CGFloat = 10
        static let pageDotSize: CGFloat = 6
        static let pageDotActiveOpacity: CGFloat = 1.0
        static let pageDotInactiveOpacity: CGFloat = 0.35
        static let pageDotsSpacing: CGFloat = 6

        // Middle Quick Toolbar
        static let toolButtonSize: CGFloat = 52
        static let toolButtonRadius: CGFloat = 10
        static let toolIconSize: CGFloat = 18
        static let toolLabelFontSize: CGFloat = 10
        static let toolSpacing: CGFloat = 8

        // Bottom Action Bar
        static let thumbnailSize: CGFloat = 44
        static let thumbnailRadius: CGFloat = 6
        static let thumbnailActiveBorderWidth: CGFloat = 2
        static let thumbnailStripMaxWidth: CGFloat = 160
        static let nextButtonHorizontalPadding: CGFloat = 20
        static let nextButtonVerticalPadding: CGFloat = 10
        static let nextButtonFontSize: CGFloat = 14
        static let nextButtonIconSize: CGFloat = 12

        // Opacity & Styling
        static let darkControlBackgroundOpacity: CGFloat = 0.55
        static let darkControlStrokeOpacity: CGFloat = 0.15
        static let headerTopPadding: CGFloat = 8
        static let audioBadgeVerticalPadding: CGFloat = 1
        static let audioBadgeHorizontalPadding: CGFloat = 3
    }

    @State private var viewModel: CreatePostViewModel
    @State private var isShowingCamera = false
    @State private var isShowingLocationPicker = false
    @State private var isShowingAudioPicker = false
    @State private var additionalMediaPickerItems: [PhotosPickerItem] = []
    @Environment(\.dismiss) private var dismiss

    init(viewModel: CreatePostViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                switch viewModel.currentStep {
                case .selectMedia:
                    mediaSelectionSplitView
                case .applyFilter:
                    modernStudioEditorView
                case .captionAndShare:
                    captionAndShareView
                }
            }
            .background(viewModel.currentStep == .applyFilter ? Color.black : Color(.systemBackground))
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(viewModel.currentStep == .applyFilter ? .hidden : .visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel.currentStep == .selectMedia {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                    } else if viewModel.currentStep == .captionAndShare {
                        Button {
                            viewModel.goToPreviousStep()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
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
                        .fontWeight(.bold)
                        .foregroundStyle(ColorTokens.accentPrimary)
                        .disabled(!viewModel.canPublish)
                    } else if viewModel.currentStep == .selectMedia {
                        Button(L10n.Common.next) {
                            Task {
                                await viewModel.goToNextStep()
                            }
                        }
                        .fontWeight(.bold)
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
            .sheet(isPresented: $isShowingLocationPicker) {
                LocationPickerSheet { loc in
                    viewModel.location = loc
                }
            }
            .sheet(isPresented: $isShowingAudioPicker) {
                StudioAudioPickerSheet(selectedTrack: $viewModel.currentAudioTrack)
            }
            .onChange(of: additionalMediaPickerItems) { _, items in
                guard !items.isEmpty else { return }
                Task {
                    var newDatas: [Data] = []
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            newDatas.append(data)
                        }
                    }
                    if !newDatas.isEmpty {
                        viewModel.appendSelectedImageData(newDatas)
                    }
                    additionalMediaPickerItems = []
                }
            }
            .task {
                await viewModel.loadInitialLibrary()
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

    // MARK: - Step 1: Media Selection (50/50 Split View)

    private var mediaSelectionSplitView: some View {
        GeometryReader { geometry in
            let previewHeight = geometry.size.height * 0.48

            VStack(spacing: 0) {
                // Top Viewport Preview (48% height)
                topPreviewViewport
                    .frame(height: previewHeight)
                    .background(Color.black)

                // Middle Bar: Album Dropdown + Multi-Select + Camera
                middleControlBar

                // Bottom 4-Column Grid (Remaining height)
                bottomMediaGrid
            }
        }
    }

    // MARK: - Top Preview Viewport

    private var topPreviewViewport: some View {
        ZStack(alignment: .bottom) {
            Color.black

            if let previewImage = viewModel.activePreviewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .aspectRatio(viewModel.aspectRatio.ratioValue, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else if viewModel.isLoadingAssets {
                ProgressView()
                    .tint(.white)
            } else {
                VStack(spacing: DS.Spacing.xs) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 44))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Chọn ảnh từ thư viện bên dưới")
                        .font(DS.Font.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            // Floating Controls: Aspect Ratio Toggle (1:1 / 4:5)
            HStack {
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
            }
            .padding(DS.Spacing.sm)
        }
    }

    // MARK: - Middle Control Bar

    private var middleControlBar: some View {
        HStack {
            // Album Picker Menu (Recents, Favorites, Videos...)
            Menu {
                ForEach(viewModel.albums) { album in
                    Button {
                        Task { await viewModel.selectAlbum(album) }
                    } label: {
                        HStack {
                            Text(album.title)
                            Spacer()
                            Text("\(album.count)")
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.selectedAlbum?.title ?? "Gần đây")
                        .font(DS.Font.headline)
                        .foregroundStyle(.primary)

                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
            }

            Spacer()

            HStack(spacing: DS.Spacing.sm) {
                // Multi-Select Mode Button
                Button {
                    viewModel.toggleMultiSelect()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isMultiSelectEnabled ? "square.on.square.fill" : "square.on.square")
                            .font(.caption)
                        Text("CHỌN NHIỀU")
                            .font(DS.Font.caption2)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(viewModel.isMultiSelectEnabled ? .white : .primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        viewModel.isMultiSelectEnabled ? ColorTokens.accentPrimary : Color(.systemGray6),
                        in: Capsule()
                    )
                }
            }
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.vertical, DS.Spacing.xs)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom)
    }

    // MARK: - Bottom Media Grid

    private var bottomMediaGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 1.5), count: 4),
                spacing: 1.5
            ) {
                // Cell 0: Interactive Camera Tile
                Button {
                    isShowingCamera = true
                } label: {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            ZStack {
                                Color(.systemGray6)
                                VStack(spacing: 4) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.primary)
                                    Text("Máy ảnh")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .clipped()
                }
                .buttonStyle(.plain)

                ForEach(viewModel.mediaAssets) { asset in
                    let isSelected = viewModel.selectedMediaAssets.contains(asset)
                    let selectionIndex = viewModel.selectedMediaAssets.firstIndex(of: asset)

                    AssetThumbnailCell(
                        asset: asset,
                        isActive: viewModel.activeAsset == asset,
                        isMultiSelectEnabled: viewModel.isMultiSelectEnabled,
                        isSelected: isSelected,
                        selectionIndex: selectionIndex
                    )
                    .onTapGesture {
                        viewModel.toggleAssetSelection(asset)
                    }
                }
            }
            .padding(.bottom, 64)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Step 2: Modern Studio Editor (TikTok / Reference Layout)

    private var modernStudioEditorView: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. Top Header: Close Button + Audio Selector Pill
                studioTopHeader
                    .padding(.horizontal, DS.Padding.horizontal)
                    .padding(.top, Constants.headerTopPadding)

                Spacer(minLength: DS.Spacing.xs)

                // 2. Center Media Card with Rounded Corners + Delete (X) + Page Dots
                studioMediaCard
                    .padding(.horizontal, DS.Padding.horizontal)

                Spacer(minLength: DS.Spacing.xs)

                // 3. Middle Quick-Action Toolbar: 6 Tools
                studioQuickToolbar
                    .padding(.horizontal, DS.Padding.horizontal)
                    .padding(.bottom, DS.Spacing.xs)

                // 4. Active Drawer Panel (Filter / Adjustments / Audio / Text / Overlay)
                if let drawer = viewModel.activeStudioDrawer {
                    studioDrawerPanel(drawer)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, DS.Spacing.xs)
                }

                // 5. Bottom Action Bar: Selected Thumbnails + Add Button + Next Button (Tiếp ➔)
                studioBottomActionBar
                    .padding(.horizontal, DS.Padding.horizontal)
                    .padding(.bottom, DS.Spacing.sm)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: viewModel.activeStudioDrawer)
    }

    // MARK: - Studio Top Header

    private var studioTopHeader: some View {
        HStack {
            // Close Button (X)
            Button {
                viewModel.goToPreviousStep()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: Constants.closeIconSize, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: Constants.closeButtonSize, height: Constants.closeButtonSize)
                    .background(Color.white.opacity(Constants.darkControlBackgroundOpacity), in: Circle())
            }

            Spacer()

            // Audio Selector Pill
            if let audio = viewModel.currentAudioTrack {
                Button {
                    isShowingAudioPicker = true
                } label: {
                    HStack(spacing: DS.Spacing.xs) {
                        // Album Artwork / Music Icon Thumbnail
                        ZStack {
                            Color.black.opacity(0.8)
                            Image(systemName: "music.note")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .frame(width: Constants.audioCoverSize, height: Constants.audioCoverSize)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.audioCoverRadius))

                        // Song Details
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 9, weight: .bold))

                                Text(audio.title)
                                    .font(.system(size: Constants.audioTitleFontSize, weight: .semibold))
                                    .lineLimit(1)

                                if audio.isExplicit {
                                    Text("E")
                                        .font(.system(size: Constants.audioBadgeFontSize, weight: .heavy))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, Constants.audioBadgeHorizontalPadding)
                                        .padding(.vertical, Constants.audioBadgeVerticalPadding)
                                        .background(Color.white.opacity(0.3), in: RoundedRectangle(cornerRadius: 2))
                                }

                                if let tag = audio.badgeText {
                                    Text(tag)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }
                            .foregroundStyle(.white)

                            Text(audio.subtitle)
                                .font(.system(size: Constants.audioSubtitleFontSize))
                                .foregroundStyle(.white.opacity(0.65))
                                .lineLimit(1)
                        }

                        // Plus Button
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: Constants.audioPlusButtonSize, height: Constants.audioPlusButtonSize)

                            Image(systemName: "plus")
                                .font(.system(size: Constants.audioPlusIconSize, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.leading, 6)
                    .padding(.trailing, 10)
                    .frame(height: Constants.audioPillHeight)
                    .background(Color.black.opacity(Constants.darkControlBackgroundOpacity), in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(Constants.darkControlStrokeOpacity), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Balance placeholder for symmetrical alignment
            Color.clear
                .frame(width: Constants.closeButtonSize, height: Constants.closeButtonSize)
        }
    }

    // MARK: - Studio Media Card

    private var studioMediaCard: some View {
        VStack(spacing: Constants.pageDotsSpacing) {
            ZStack(alignment: .topTrailing) {
                // Card Media Canvas
                ZStack {
                    Color(white: 0.08)

                    if !viewModel.selectedImages.isEmpty {
                        TabView(selection: $viewModel.activeImageIndex) {
                            ForEach(0..<viewModel.selectedImages.count, id: \.self) { idx in
                                if let image = UIImage(data: viewModel.selectedImages[idx]) {
                                    FilteredImagePreview(
                                        sourceImage: image,
                                        filterId: viewModel.selectedFilterId,
                                        intensity: viewModel.filterIntensity,
                                        brightness: viewModel.brightness,
                                        contrast: viewModel.contrast,
                                        saturation: viewModel.saturation,
                                        warmth: viewModel.warmth
                                    )
                                    .aspectRatio(viewModel.aspectRatio.ratioValue, contentMode: .fit)
                                    .tag(idx)
                                }
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: Constants.mediaCardRadius))

                // Delete Button (X) at Top-Right of Card
                if !viewModel.selectedImages.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.removeSelectedImage(at: viewModel.activeImageIndex)
                        }
                        HapticFeedbackSafe.impact(.medium)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: Constants.deleteIconSize, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: Constants.deleteButtonSize, height: Constants.deleteButtonSize)
                            .background(Color.black.opacity(0.65), in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 0.8))
                    }
                    .padding(Constants.deleteButtonInset)
                }
            }
            .frame(maxHeight: Constants.mediaCardMaxHeight)

            // Page Indicator Dots
            if viewModel.selectedImages.count > 1 {
                HStack(spacing: Constants.pageDotsSpacing) {
                    ForEach(0..<viewModel.selectedImages.count, id: \.self) { idx in
                        Circle()
                            .fill(
                                viewModel.activeImageIndex == idx
                                    ? Color.white.opacity(Constants.pageDotActiveOpacity)
                                    : Color.white.opacity(Constants.pageDotInactiveOpacity)
                            )
                            .frame(width: Constants.pageDotSize, height: Constants.pageDotSize)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Studio Quick Toolbar

    private var studioQuickToolbar: some View {
        HStack(spacing: Constants.toolSpacing) {
            ForEach(StudioTool.allCases) { tool in
                Button {
                    handleToolTap(tool)
                    HapticFeedbackSafe.impact(.light)
                } label: {
                    VStack(spacing: 4) {
                        if tool == .text {
                            Text("Aa")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        } else {
                            Image(systemName: tool.iconName)
                                .font(.system(size: Constants.toolIconSize, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                        Text(tool.rawValue)
                            .font(.system(size: Constants.toolLabelFontSize, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: Constants.toolButtonSize)
                    .background(
                        viewModel.activeStudioDrawer == tool
                            ? Color.white.opacity(0.3)
                            : Color(white: 0.16),
                        in: RoundedRectangle(cornerRadius: Constants.toolButtonRadius)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Studio Drawer Panel

    @ViewBuilder
    private func studioDrawerPanel(_ drawer: StudioTool) -> some View {
        VStack(spacing: DS.Spacing.xs) {
            switch drawer {
            case .filter:
                studioFilterDrawer
            case .edit:
                studioAdjustmentsDrawer
            case .audio:
                studioAudioQuickDrawer
            case .ratio:
                studioRatioQuickDrawer
            case .text:
                studioTextQuickDrawer
            case .overlay:
                studioOverlayQuickDrawer
            }
        }
        .padding(.vertical, DS.Spacing.xs)
        .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: DS.Radius.medium))
    }

    // MARK: - Studio Drawers

    private var studioFilterDrawer: some View {
        VStack(spacing: DS.Spacing.xs) {
            if let firstData = viewModel.selectedImages.first,
               let sourceImage = UIImage(data: firstData) {
                FilterSelectionView(
                    selectedFilterId: $viewModel.selectedFilterId,
                    filterIntensity: $viewModel.filterIntensity,
                    sourceImage: sourceImage,
                    showsPreview: false
                )
            }
        }
    }

    private var studioAdjustmentsDrawer: some View {
        VStack(spacing: DS.Spacing.xs) {
            if let adjustment = viewModel.activeAdjustment {
                HStack(spacing: DS.Spacing.sm) {
                    Text(adjustment.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 80, alignment: .leading)

                    switch adjustment {
                    case .brightness:
                        Slider(value: $viewModel.brightness, in: -0.5...0.5)
                            .tint(.white)
                    case .contrast:
                        Slider(value: $viewModel.contrast, in: 0.5...1.5)
                            .tint(.white)
                    case .saturation:
                        Slider(value: $viewModel.saturation, in: 0.0...2.0)
                            .tint(.white)
                    case .warmth:
                        Slider(value: $viewModel.warmth, in: -0.5...0.5)
                            .tint(.white)
                    }

                    Button("Đặt lại") {
                        switch adjustment {
                        case .brightness: viewModel.brightness = 0.0
                        case .contrast: viewModel.contrast = 1.0
                        case .saturation: viewModel.saturation = 1.0
                        case .warmth: viewModel.warmth = 0.0
                        }
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, DS.Padding.horizontal)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.md) {
                    ForEach(PostAdjustmentType.allCases) { type in
                        Button {
                            withAnimation {
                                viewModel.activeAdjustment = type
                            }
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: type.iconName)
                                    .font(.system(size: 16))
                                Text(type.rawValue)
                                    .font(.system(size: 10))
                            }
                            .foregroundStyle(viewModel.activeAdjustment == type ? ColorTokens.accentPrimary : .white.opacity(0.75))
                            .frame(width: 58)
                        }
                    }
                }
                .padding(.horizontal, DS.Padding.horizontal)
            }
        }
    }

    private var studioAudioQuickDrawer: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "music.note")
                .foregroundStyle(ColorTokens.accentPrimary)
            Text(viewModel.currentAudioTrack?.title ?? "Chưa chọn âm thanh")
                .font(DS.Font.subheadline)
                .foregroundStyle(.white)
            Spacer()
            Button("Thay đổi") {
                isShowingAudioPicker = true
            }
            .font(DS.Font.captionBold)
            .foregroundStyle(ColorTokens.accentPrimary)
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.vertical, DS.Spacing.xxs)
    }

    private var studioRatioQuickDrawer: some View {
        HStack(spacing: DS.Spacing.lg) {
            ForEach(PostAspectRatio.allCases) { ratio in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        viewModel.aspectRatio = ratio
                    }
                    HapticFeedbackSafe.selection()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: ratio == .full ? "iphone" : "aspectratio")
                            .font(.system(size: 16))
                        Text(ratio.rawValue)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(viewModel.aspectRatio == ratio ? ColorTokens.accentPrimary : .white.opacity(0.75))
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.vertical, DS.Spacing.xxs)
    }

    private var studioTextQuickDrawer: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "textformat")
                .foregroundStyle(.white)
            Text("Chạm vào ảnh để thêm chữ nghệ thuật")
                .font(DS.Font.caption)
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.vertical, DS.Spacing.xxs)
    }

    private var studioOverlayQuickDrawer: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "square.2.layers.3d")
                .foregroundStyle(.white)
            Text("Thêm lớp phủ hình ảnh hoặc nhãn dán")
                .font(DS.Font.caption)
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.vertical, DS.Spacing.xxs)
    }

    // MARK: - Studio Bottom Action Bar

    private var studioBottomActionBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            // Selected Thumbnails Strip + Add Button
            HStack(spacing: DS.Spacing.xs) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.xs) {
                        ForEach(0..<viewModel.selectedImages.count, id: \.self) { idx in
                            if let img = ImageDownsampler.shared.downsample(data: viewModel.selectedImages[idx], maxDimension: 120) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.activeImageIndex = idx
                                    }
                                    HapticFeedbackSafe.selection()
                                } label: {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: Constants.thumbnailSize, height: Constants.thumbnailSize)
                                        .clipShape(RoundedRectangle(cornerRadius: Constants.thumbnailRadius))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Constants.thumbnailRadius)
                                                .stroke(
                                                    viewModel.activeImageIndex == idx ? Color.white : Color.clear,
                                                    lineWidth: Constants.thumbnailActiveBorderWidth
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(maxWidth: Constants.thumbnailStripMaxWidth)

                // Add More Media Button (+) via PhotosPicker
                PhotosPicker(
                    selection: $additionalMediaPickerItems,
                    maxSelectionCount: max(1, 10 - viewModel.selectedImages.count),
                    matching: .images
                ) {
                    ZStack {
                        Color(white: 0.18)
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: Constants.thumbnailSize, height: Constants.thumbnailSize)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.thumbnailRadius))
                }
            }

            Spacer()

            // Vibrant Blue "Tiếp ➔" Button
            Button {
                Task {
                    await viewModel.goToNextStep()
                }
                HapticFeedbackSafe.impact(.medium)
            } label: {
                HStack(spacing: 6) {
                    Text(L10n.Common.next)
                        .font(.system(size: Constants.nextButtonFontSize, weight: .bold))

                    Image(systemName: "arrow.right")
                        .font(.system(size: Constants.nextButtonIconSize, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, Constants.nextButtonHorizontalPadding)
                .padding(.vertical, Constants.nextButtonVerticalPadding)
                .background(ColorTokens.accentPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func handleToolTap(_ tool: StudioTool) {
        switch tool {
        case .ratio:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                viewModel.cycleAspectRatio()
            }
        case .audio:
            isShowingAudioPicker = true
        case .text:
            viewModel.toggleStudioDrawer(.text)
        case .overlay:
            viewModel.toggleStudioDrawer(.overlay)
        case .filter:
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.toggleStudioDrawer(.filter)
            }
        case .edit:
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.toggleStudioDrawer(.edit)
            }
        }
    }

    // MARK: - Step 3: Caption, Details & Share

    private var captionAndShareView: some View {
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

                // Add Music Row
                Button {
                    HUDManager.shared.showInfo("Thêm nhạc nền vào bài viết")
                } label: {
                    HStack {
                        Image(systemName: "music.note")
                            .font(.body)
                            .frame(width: 24)
                        Text("Thêm nhạc")
                            .font(DS.Font.body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.primary)
                }
                .padding(.horizontal, DS.Padding.horizontal)

                Divider()

                // Tag People Row
                Button {
                    HUDManager.shared.showInfo("Chạm vào ảnh để gắn thẻ người dùng")
                } label: {
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .font(.body)
                            .frame(width: 24)
                        Text(L10n.CreatePost.tagPeople)
                            .font(DS.Font.body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.primary)
                }
                .padding(.horizontal, DS.Padding.horizontal)

                Divider()

                // Add Location Row
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.body)
                        .frame(width: 24)
                    Button {
                        isShowingLocationPicker = true
                    } label: {
                        Text(viewModel.location?.name ?? L10n.CreatePost.addLocation)
                            .font(DS.Font.body)
                            .foregroundStyle(viewModel.location != nil ? ColorTokens.accentPrimary : .primary)
                    }

                    Spacer()

                    if viewModel.location != nil {
                        Button {
                            viewModel.location = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, DS.Padding.horizontal)

                Divider()

                // Audience Picker
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text(L10n.CreatePost.audience)
                        .font(DS.Font.subheadlineBold)
                    Picker(L10n.CreatePost.audience, selection: $viewModel.isCloseFriendsOnly) {
                        Text(L10n.CreatePost.everyone).tag(false)
                        Text(L10n.CreatePost.closeFriends).tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, DS.Padding.horizontal)

                Divider()

                // Advanced Settings
                DisclosureGroup(L10n.CreatePost.advancedSettings) {
                    VStack(spacing: DS.Spacing.sm) {
                        Toggle(L10n.CreatePost.hideLikes, isOn: $viewModel.hideLikes)
                        Toggle(L10n.CreatePost.turnOffComments, isOn: $viewModel.disableComments)
                        Toggle("Chia sẻ lên Facebook", isOn: $viewModel.shareToFacebook)
                    }
                    .padding(.top, DS.Spacing.xs)
                }
                .padding(.horizontal, DS.Padding.horizontal)
            }
            .padding(.vertical, DS.Spacing.sm)
        }
    }
}

// MARK: - AssetThumbnailCell

struct AssetThumbnailCell: View {
    let asset: MediaAssetItem
    let isActive: Bool
    let isMultiSelectEnabled: Bool
    let isSelected: Bool
    let selectionIndex: Int?

    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color(.systemGray5)
                    }
                }
                .clipped()
                .overlay(
                    isActive ? Color.white.opacity(0.25) : Color.clear
                )

            // Video duration badge
            if asset.isVideo {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(asset.formattedDuration)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 3))
                    }
                    .padding(3)
                }
            }

            // Multi-Select Index Badge
            if isMultiSelectEnabled {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 1.5)
                        .frame(width: 22, height: 22)

                    if isSelected, let idx = selectionIndex {
                        Circle()
                            .fill(ColorTokens.accentPrimary)
                            .frame(width: 22, height: 22)

                        Text("\(idx + 1)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Circle()
                            .fill(Color.black.opacity(0.2))
                            .frame(width: 22, height: 22)
                    }
                }
                .padding(4)
            }
        }
        .task {
            thumbnail = await PhotoLibraryService.shared.loadThumbnail(for: asset.phAsset)
        }
    }
}

// MARK: - FilteredImagePreview

struct FilteredImagePreview: View {
    let sourceImage: UIImage
    let filterId: String
    let intensity: Float
    let brightness: Float
    let contrast: Float
    let saturation: Float
    let warmth: Float

    @State private var preview: UIImage?

    var body: some View {
        Group {
            if let preview {
                Image(uiImage: preview)
                    .resizable()
            } else {
                Image(uiImage: sourceImage)
                    .resizable()
            }
        }
        .task(id: filterId) { update() }
        .onChange(of: intensity) { _, _ in update() }
        .onChange(of: brightness) { _, _ in update() }
        .onChange(of: contrast) { _, _ in update() }
        .onChange(of: saturation) { _, _ in update() }
        .onChange(of: warmth) { _, _ in update() }
    }

    private func update() {
        guard var ciImage = CIImage(image: sourceImage) else { return }

        // Filter
        if filterId != "original", let filter = FilterRegistry.filter(byId: filterId) {
            ciImage = FilterEngine.shared.apply(filter: filter, to: ciImage, intensity: intensity)
        }

        // Adjustments
        if brightness != 0.0 || contrast != 1.0 || saturation != 1.0 {
            let colorControls = CIFilter.colorControls()
            colorControls.inputImage = ciImage
            colorControls.brightness = brightness
            colorControls.contrast = contrast
            colorControls.saturation = saturation
            if let out = colorControls.outputImage { ciImage = out }
        }

        if warmth != 0.0 {
            let tempFilter = CIFilter.temperatureAndTint()
            tempFilter.inputImage = ciImage
            tempFilter.neutral = CIVector(x: CGFloat(6500.0 + Double(warmth * 2500.0)), y: 0)
            if let out = tempFilter.outputImage { ciImage = out }
        }

        preview = FilterEngine.shared.renderToUIImage(ciImage)
    }
}

// MARK: - StudioAudioPickerSheet

struct StudioAudioPickerSheet: View {
    @Binding var selectedTrack: PostAudioTrackItem?
    @Environment(\.dismiss) private var dismiss

    private enum Constants {
        static let iconContainerSize: CGFloat = 44
        static let rowVerticalPadding: CGFloat = 4
        static let badgeFontSize: CGFloat = 9
        static let badgeCornerRadius: CGFloat = 2
        static let badgeHorizontalPadding: CGFloat = 3
        static let badgeVerticalPadding: CGFloat = 1
    }

    private let presetTracks: [PostAudioTrackItem] = [
        PostAudioTrackItem(
            id: "mck_cam_on",
            title: "MCK · Cảm Ơn",
            artist: "RP",
            isExplicit: true,
            badgeText: "RP",
            subtitle: "Âm thanh gợi ý"
        ),
        PostAudioTrackItem(
            id: "wren_to_te_ti",
            title: "Tò Te Tí",
            artist: "Wren Evans",
            isExplicit: false,
            badgeText: "HOT",
            subtitle: "Thịnh hành trên mạng"
        ),
        PostAudioTrackItem(
            id: "mtp_dung_lam_trai_tim",
            title: "Đừng Làm Trái Tim Anh Đau",
            artist: "Sơn Tùng M-TP",
            isExplicit: false,
            badgeText: "TOP 1",
            subtitle: "Âm thanh được dùng nhiều"
        ),
        PostAudioTrackItem(
            id: "mono_waiting_for_you",
            title: "Waiting For You",
            artist: "MONO",
            isExplicit: false,
            badgeText: nil,
            subtitle: "Nhạc thịnh hành"
        ),
        PostAudioTrackItem(
            id: "vu_la_lung",
            title: "Lạ Lùng",
            artist: "Vũ.",
            isExplicit: false,
            badgeText: nil,
            subtitle: "Giai điệu nhẹ nhàng"
        )
    ]

    var body: some View {
        NavigationStack {
            List(presetTracks) { track in
                Button {
                    selectedTrack = track
                    HapticFeedbackSafe.impact(.light)
                    dismiss()
                } label: {
                    HStack(spacing: DS.Spacing.sm) {
                        ZStack {
                            Color(.systemGray5)
                            Image(systemName: "music.note")
                                .foregroundStyle(ColorTokens.accentPrimary)
                        }
                        .frame(width: Constants.iconContainerSize, height: Constants.iconContainerSize)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(track.title)
                                    .font(DS.Font.headline)
                                    .foregroundStyle(.primary)

                                if track.isExplicit {
                                    Text("E")
                                        .font(.system(size: Constants.badgeFontSize, weight: .bold))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, Constants.badgeHorizontalPadding)
                                        .padding(.vertical, Constants.badgeVerticalPadding)
                                        .background(Color(.systemGray4), in: RoundedRectangle(cornerRadius: Constants.badgeCornerRadius))
                                }
                            }

                            Text("\(track.artist) · \(track.subtitle)")
                                .font(DS.Font.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if selectedTrack?.id == track.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(ColorTokens.accentPrimary)
                                .fontWeight(.bold)
                        }
                    }
                    .padding(.vertical, Constants.rowVerticalPadding)
                }
            }
            .navigationTitle("Chọn âm thanh")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}
