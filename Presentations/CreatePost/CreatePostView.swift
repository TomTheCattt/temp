//
//  CreatePostView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import Photos

// MARK: - StudioTab

enum StudioTab: String, CaseIterable, Identifiable {
    case filter = "BỘ LỌC"
    case edit = "CHỈNH SỬA"

    var id: String { rawValue }
}

// MARK: - CreatePostView

/// Instagram-standard Post Creation View matching iOS Instagram:
/// 1. Screen 1: 50/50 Split View (Top Media Preview + Middle Bar + Bottom Native Camera Roll Grid).
/// 2. Screen 2: Filter & Edit Studio (Color Presets & Fine-tuning adjustments).
/// 3. Screen 3: Share Details (Caption, Tags, Music, Location, Privacy & Publish).
struct CreatePostView: View {

    @State private var viewModel: CreatePostViewModel
    @State private var activeStudioTab: StudioTab = .filter
    @State private var isShowingCamera = false
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
                    mediaSelectionSplitView
                case .applyFilter:
                    filterAndEditStudioView
                case .captionAndShare:
                    captionAndShareView
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
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
                    } else {
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
                    } else {
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

    // MARK: - Step 2: Filter & Edit Studio

    private var filterAndEditStudioView: some View {
        VStack(spacing: 0) {
            // Preview Carousel
            ZStack {
                Color.black

                if !viewModel.selectedImages.isEmpty {
                    let safeIndex = min(viewModel.activeImageIndex, viewModel.selectedImages.count - 1)
                    if let image = UIImage(data: viewModel.selectedImages[safeIndex]) {
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)

            // Multi-image switcher thumbnail strip
            if viewModel.selectedImages.count > 1 {
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
                                            .stroke(viewModel.activeImageIndex == idx ? ColorTokens.accentPrimary : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        viewModel.activeImageIndex = idx
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, DS.Padding.horizontal)
                    .padding(.vertical, 6)
                }
                .background(Color(.systemBackground))
            }

            // Studio Tabs: BỘ LỌC vs CHỈNH SỬA
            HStack(spacing: 0) {
                Button {
                    activeStudioTab = .filter
                } label: {
                    VStack(spacing: 6) {
                        Text(StudioTab.filter.rawValue)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(activeStudioTab == .filter ? .primary : .secondary)

                        Rectangle()
                            .fill(activeStudioTab == .filter ? Color.primary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)

                Button {
                    activeStudioTab = .edit
                } label: {
                    VStack(spacing: 6) {
                        Text(StudioTab.edit.rawValue)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(activeStudioTab == .edit ? .primary : .secondary)

                        Rectangle()
                            .fill(activeStudioTab == .edit ? Color.primary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemBackground))

            // Tab Content
            if activeStudioTab == .filter {
                filterTabContent
            } else {
                editAdjustmentTabContent
            }

            Spacer()
        }
    }

    // MARK: - Filter Tab Content

    private var filterTabContent: some View {
        VStack(spacing: 0) {
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

    // MARK: - Edit Adjustment Tab Content

    private var editAdjustmentTabContent: some View {
        VStack(spacing: DS.Spacing.md) {
            // Active adjustment slider
            if let adjustment = viewModel.activeAdjustment {
                HStack(spacing: DS.Spacing.md) {
                    Text(adjustment.rawValue)
                        .font(DS.Font.caption)
                        .frame(width: 80, alignment: .leading)

                    switch adjustment {
                    case .brightness:
                        Slider(value: $viewModel.brightness, in: -0.5...0.5)
                    case .contrast:
                        Slider(value: $viewModel.contrast, in: 0.5...1.5)
                    case .saturation:
                        Slider(value: $viewModel.saturation, in: 0.0...2.0)
                    case .warmth:
                        Slider(value: $viewModel.warmth, in: -0.5...0.5)
                    }

                    Button("Đặt lại") {
                        switch adjustment {
                        case .brightness: viewModel.brightness = 0.0
                        case .contrast: viewModel.contrast = 1.0
                        case .saturation: viewModel.saturation = 1.0
                        case .warmth: viewModel.warmth = 0.0
                        }
                    }
                    .font(DS.Font.caption2)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, DS.Padding.horizontal)
                .padding(.top, DS.Spacing.sm)
            }

            // Adjustment tools scroll strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.lg) {
                    ForEach(PostAdjustmentType.allCases) { type in
                        Button {
                            withAnimation {
                                viewModel.activeAdjustment = type
                            }
                        } label: {
                            VStack(spacing: DS.Spacing.xs) {
                                Image(systemName: type.iconName)
                                    .font(.title3)
                                Text(type.rawValue)
                                    .font(DS.Font.caption2)
                            }
                            .foregroundStyle(viewModel.activeAdjustment == type ? ColorTokens.accentPrimary : .secondary)
                            .frame(width: 64)
                        }
                    }
                }
                .padding(.horizontal, DS.Padding.horizontal)
                .padding(.vertical, DS.Spacing.sm)
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
