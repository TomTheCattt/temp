//
//  StoryCameraView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import PhotosUI
import AVKit

// MARK: - StoryCameraView

/// Authentic Instagram Story Camera & Editor matching iOS Instagram:
/// 1. Story Camera: 9:16 viewfinder, left vertical tools (Create Aa, Layout, Boomerang, Hands-Free),
///    central shutter with press-to-record ring, and bottom-left camera roll shortcut.
/// 2. Story Editor: Interactive Typography (Aa), Sticker Drawer (PIP Photo, Poll, Mention),
///    screen swipe color filters (Paris, Oslo, Tokyo), and 1-tap "Your Story" / "Close Friends" publish.
@MainActor
struct StoryCameraView: View {

    @State private var viewModel: StoryCameraViewModel
    @State private var selectedGalleryItem: PhotosPickerItem?
    @State private var isShowingCreateCanvas = false
    @State private var isShowingLayoutCollage = false
    @State private var isShowingStickerDrawer = false
    @State private var isLeftMenuExpanded = false

    // Inline Text Editor State
    @State private var isEditingText = false
    @State private var editingItemId: UUID?
    @State private var editingText = ""
    @State private var editingColor: Color = .white
    @State private var editingHasBackground = true
    @State private var editingFontStyle: TextFontStyle = .modern
    @State private var editingAlignment: TextAlignment = .center
    @FocusState private var isFieldFocused: Bool

    // Filter swipe announcement state
    @State private var filterAnnouncement: String? = nil

    @Environment(\.dismiss) private var dismiss

    private let availableColors: [Color] = [
        .white,
        .black,
        Color(red: 1.0, green: 0.85, blue: 0.0), // Yellow
        Color.orange,
        Color.red,
        Color.pink,
        Color.purple,
        Color.blue,
        Color.green
    ]

    var stopCameraOnDisappear: Bool = true
    /// The creation hub owns the only AVCaptureVideoPreviewLayer while tabs are persistent.
    var usesSharedCameraPreview: Bool = false
    var isCameraModeActive: Bool = true

    init(
        viewModel: StoryCameraViewModel,
        stopCameraOnDisappear: Bool = true,
        usesSharedCameraPreview: Bool = false,
        isCameraModeActive: Bool = true
    ) {
        _viewModel = State(initialValue: viewModel)
        self.stopCameraOnDisappear = stopCameraOnDisappear
        self.usesSharedCameraPreview = usesSharedCameraPreview
        self.isCameraModeActive = isCameraModeActive
    }

    var body: some View {
        ZStack {
            (usesSharedCameraPreview ? Color.clear : Color.black).ignoresSafeArea()

            if viewModel.isShowingPreview {
                storyEditorScreen
            } else {
                storyCameraScreen
            }
        }
        .statusBarHidden()
        .task(id: isCameraModeActive) {
            guard isCameraModeActive else { return }
            await viewModel.checkPermissions()
        }
        .onDisappear {
            if stopCameraOnDisappear {
                viewModel.cameraService.stop()
            }
        }
        .onChange(of: viewModel.isPublished) { _, published in
            if published { dismiss() }
        }
        .fullScreenCover(isPresented: $isShowingCreateCanvas) {
            CreateCanvasView(isPresented: $isShowingCreateCanvas) { bakedData, isVideo in
                viewModel.loadFromGallery(data: bakedData, isVideo: isVideo)
            }
        }
        .fullScreenCover(isPresented: $isShowingLayoutCollage) {
            LayoutCollageView(isPresented: $isShowingLayoutCollage) { collageData in
                viewModel.loadFromGallery(data: collageData, isVideo: false)
            }
        }
        .sheet(isPresented: $isShowingStickerDrawer) {
            storyStickerDrawer
        }
    }

    // MARK: - Screen 1: Story Camera

    private var storyCameraScreen: some View {
        ZStack {
            // Camera Stream / Simulator Fallback
            if viewModel.cameraPermissionGranted {
                if usesSharedCameraPreview {
                    Color.clear
                } else if viewModel.isHardwareAvailable {
                    CameraPreviewView(
                        session: viewModel.cameraService.session,
                        isHardwareAvailable: true,
                        isFrontFacing: viewModel.isFrontCamera
                    )
                    .ignoresSafeArea()
                } else {
                    simulatorMockPreview
                }
            } else {
                permissionDeniedView
            }

            // Left Vertical Tool Strip (Instagram 1:1)
            HStack {
                leftVerticalToolBar
                    .padding(.leading, 18)

                Spacer()
            }

            // Top Bar
            VStack {
                topCameraBar
                Spacer()
            }

            // Central Shutter Button (Lower Third, elevated above bottom mode switcher)
            VStack {
                Spacer()
                centralShutterButton
                    .padding(.bottom, CaptureLayoutMetrics.modeSwitcherClearance)
            }

            // Bottom Flanking Controls (Gallery Shortcut on Left, Camera Flip on Right)
            VStack {
                Spacer()
                bottomCameraControls
            }
        }
    }

    // MARK: - Left Vertical Tool Strip (Collapsed / Expanded)

    private var leftVerticalToolBar: some View {
        VStack(alignment: .leading, spacing: 22) {
            Spacer().frame(height: 100)

            if !isLeftMenuExpanded {
                // Collapsed State: Pure glyphs (matching media_1792049381031.png)
                Button {
                    isShowingCreateCanvas = true
                } label: {
                    Text("Aa")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .shadow(color: .black.opacity(0.45), radius: 3)
                }

                Button {
                    viewModel.mode = (viewModel.mode == .boomerang) ? .normal : .boomerang
                } label: {
                    Image(systemName: "infinity")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(viewModel.mode == .boomerang ? ColorTokens.accentPrimary : .white)
                        .frame(width: 32, height: 32)
                        .shadow(color: .black.opacity(0.45), radius: 3)
                }

                Button {
                    isShowingLayoutCollage = true
                } label: {
                    Image(systemName: "rectangle.split.2x1")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .shadow(color: .black.opacity(0.45), radius: 3)
                }

                Button {
                    viewModel.currentFilterIndex = (viewModel.currentFilterIndex + 1) % StoryFilter.allFilters.count
                } label: {
                    Image(systemName: "circle.hexagongrid")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .shadow(color: .black.opacity(0.45), radius: 3)
                }

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isLeftMenuExpanded = true
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .shadow(color: .black.opacity(0.45), radius: 3)
                }
            } else {
                // Expanded State: Glyphs + Labels (matching media_1792049565500.png)
                Button {
                    isShowingCreateCanvas = true
                } label: {
                    HStack(spacing: 14) {
                        Text("Aa")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .frame(width: 32, alignment: .center)
                        Text("Tạo")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.45), radius: 3)
                }

                Button {
                    viewModel.mode = (viewModel.mode == .boomerang) ? .normal : .boomerang
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "infinity")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(width: 32, alignment: .center)
                        Text("Boomerang")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(viewModel.mode == .boomerang ? ColorTokens.accentPrimary : .white)
                    .shadow(color: .black.opacity(0.45), radius: 3)
                }

                Button {
                    isShowingLayoutCollage = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "rectangle.split.2x1")
                            .font(.system(size: 20, weight: .medium))
                            .frame(width: 32, alignment: .center)
                        Text("Bố cục")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.45), radius: 3)
                }

                Button {
                    viewModel.currentFilterIndex = (viewModel.currentFilterIndex + 1) % StoryFilter.allFilters.count
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "circle.hexagongrid")
                            .font(.system(size: 20, weight: .medium))
                            .frame(width: 32, alignment: .center)

                        HStack(spacing: 6) {
                            Text("MỚI")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 3))

                            Text("Hiệu ứng")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.45), radius: 3)
                }

                Button {
                    viewModel.mode = (viewModel.mode == .hands_free) ? .normal : .hands_free
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "circle.inset.filled")
                            .font(.system(size: 20, weight: .medium))
                            .frame(width: 32, alignment: .center)
                        Text("Rảnh tay")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(viewModel.mode == .hands_free ? ColorTokens.accentPrimary : .white)
                    .shadow(color: .black.opacity(0.45), radius: 3)
                }

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isLeftMenuExpanded = false
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 32, alignment: .center)
                        Text("Đóng")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.45), radius: 3)
                }
            }

            Spacer()
        }
    }

    // MARK: - Top Camera Bar

    private var topCameraBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.45), radius: 3)
            }

            Spacer()

            Button(action: { viewModel.toggleFlash() }) {
                Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(viewModel.isFlashOn ? .yellow : .white)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.45), radius: 3)
            }

            Spacer()

            Button(action: { /* Settings */ }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.45), radius: 3)
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.top, DS.Spacing.md)
    }

    // MARK: - Central Shutter Button

    private var centralShutterButton: some View {
        Button(action: {
            if viewModel.mode == .hands_free || viewModel.isRecording {
                viewModel.stopRecording()
            } else {
                viewModel.capturePhoto()
            }
        }) {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 80, height: 80)

                Circle()
                    .fill(viewModel.isRecording ? ColorTokens.destructive : Color.white)
                    .frame(width: viewModel.isRecording ? 36 : 68, height: viewModel.isRecording ? 36 : 68)
                    .animation(.easeInOut(duration: 0.15), value: viewModel.isRecording)
            }
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    viewModel.startRecording()
                }
        )
    }

    // MARK: - Bottom Camera Controls (Gallery & Flip Flanking Bar)

    private var bottomCameraControls: some View {
        let currentThumb = viewModel.latestGalleryThumbnail
        return HStack(alignment: .center) {
            // Left: Gallery Shortcut Button
            PhotosPicker(
                selection: $selectedGalleryItem,
                matching: .any(of: [.images, .videos])
            ) {
                Group {
                    if let thumb = currentThumb {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "photo")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 1.5)
                )
                .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
            }
            .onChange(of: selectedGalleryItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        let isVideo = isVideoData(data)
                        viewModel.loadFromGallery(data: data, isVideo: isVideo)
                    }
                }
            }

            Spacer()

            // Right: Camera Rotate (Flip) Button
            Button(action: { viewModel.toggleCamera() }) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.55), in: Circle())
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.bottom, DS.Spacing.md)
    }

    // MARK: - Screen 2: Story Editor

    private var storyEditorScreen: some View {
        ZStack {
            // Preview Image / Video with Filter Applied
            Group {
                if let data = viewModel.capturedImageData,
                   let uiImage = UIImage(data: data) {
                    FilteredImagePreview(
                        sourceImage: uiImage,
                        filterId: viewModel.currentFilter.filterId,
                        intensity: 1.0,
                        brightness: 0.0,
                        contrast: 1.0,
                        saturation: 1.0,
                        warmth: 0.0
                    )
                    .aspectRatio(9/16, contentMode: .fill)
                    .ignoresSafeArea()
                } else if let videoURL = viewModel.capturedVideoURL {
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .aspectRatio(9/16, contentMode: .fill)
                        .ignoresSafeArea()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        if value.translation.width < -50 {
                            withAnimation {
                                viewModel.nextFilter()
                                showFilterToast(viewModel.currentFilter.name)
                            }
                        } else if value.translation.width > 50 {
                            withAnimation {
                                viewModel.previousFilter()
                                showFilterToast(viewModel.currentFilter.name)
                            }
                        }
                    }
            )

            // Multi-layer Overlays: Photo PIP Stickers
            ForEach($viewModel.stickers) { $sticker in
                PhotoPIPStickerView(item: $sticker) {
                    viewModel.stickers.removeAll { $0.id == sticker.id }
                }
            }

            // Multi-layer Overlays: Typography with Tap-to-edit
            ForEach($viewModel.texts) { $textItem in
                TypographyOverlayView(
                    item: $textItem,
                    onDelete: {
                        viewModel.texts.removeAll { $0.id == textItem.id }
                    },
                    onEdit: {
                        startEditingText(item: textItem)
                    }
                )
            }

            // Filter Name Pill Toast
            if let filterName = filterAnnouncement {
                Text(filterName)
                    .font(DS.Font.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5), in: Capsule())
                    .transition(.opacity.combined(with: .scale))
            }

            // Top Floating Toolbar & Bottom 1-Tap Share Bar
            if !isEditingText {
                VStack {
                    storyEditorTopBar
                    Spacer()
                    storyEditorBottomBar
                }
            }

            // Inline Full-Screen Typography Editor
            if isEditingText {
                inlineStoryTextEditorOverlay
            }
        }
    }

    // MARK: - Story Editor Top Bar

    private var storyEditorTopBar: some View {
        HStack(spacing: DS.Spacing.md) {
            Button(action: { viewModel.retake() }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.35), in: Circle())
            }

            Spacer()

            // Tool: Add Text (Aa)
            editorToolIconButton(icon: "textformat") {
                startEditingText()
            }

            // Tool: Stickers Drawer
            editorToolIconButton(icon: "face.smiling") {
                isShowingStickerDrawer = true
            }

            // Tool: Draw Canvas
            editorToolIconButton(icon: "pencil.tip") {
                HUDManager.shared.showInfo("Công cụ vẽ tay")
            }

            // Tool: Add Music
            editorToolIconButton(icon: "music.note") {
                HUDManager.shared.showInfo("Thêm nhạc nền Story")
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.top, DS.Spacing.md)
    }

    @ViewBuilder
    private func editorToolIconButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.black.opacity(0.35), in: Circle())
        }
    }

    // MARK: - Story Editor Bottom Bar

    private var storyEditorBottomBar: some View {
        HStack(spacing: DS.Spacing.md) {
            // "Tin của bạn" (Your Story) - 1-tap publish
            Button {
                Task { await viewModel.publishStory() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.circle.fill")
                        .font(.body)
                    Text(L10n.StoryCamera.yourStory)
                        .font(DS.Font.subheadlineBold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.5), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
            }

            // "Bạn thân" (Close Friends) - 1-tap publish
            Button {
                Task { await viewModel.publishStory(isCloseFriendsOnly: true) }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "star.circle.fill")
                        .font(.body)
                        .foregroundStyle(ColorTokens.success)
                    Text(L10n.StoryCamera.closeFriends)
                        .font(DS.Font.subheadlineBold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.5), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
            }

            Spacer()

            // Next Arrow Circle
            Button {
                Task { await viewModel.publishStory() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(Color.white, in: Circle())
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.bottom, DS.Spacing.xl)
    }

    // MARK: - Story Sticker Drawer

    private var storyStickerDrawer: some View {
        StoryStickerDrawer(
            isPresented: $isShowingStickerDrawer,
            onAddPhotoSticker: { stickerData in
                viewModel.stickers.append(PIPStickerItem(imageData: stickerData))
            },
            onAddTextSticker: { textItem in
                viewModel.texts.append(textItem)
            }
        )
    }

    @ViewBuilder
    private func stickerTile(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: DS.Spacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(color, in: RoundedRectangle(cornerRadius: DS.Radius.medium))

                Text(title)
                    .font(DS.Font.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Inline Typography Editor Overlay

    private var inlineStoryTextEditorOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    finishEditingText()
                }

            VStack(spacing: 0) {
                // Top Action Toolbar
                HStack(spacing: DS.Spacing.md) {
                    Button(L10n.Common.cancel) {
                        isEditingText = false
                    }
                    .font(DS.Font.headline)
                    .foregroundStyle(.white)

                    Spacer()

                    // Text Alignment Toggle Button
                    Button {
                        switch editingAlignment {
                        case .leading: editingAlignment = .center
                        case .center: editingAlignment = .trailing
                        case .trailing: editingAlignment = .leading
                        }
                    } label: {
                        Image(systemName: alignmentIconName)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.2), in: Circle())
                    }

                    // Background Badge Toggle Button
                    Button {
                        editingHasBackground.toggle()
                    } label: {
                        Image(systemName: editingHasBackground ? "character.textbox" : "textformat")
                            .font(.title3)
                            .foregroundStyle(editingHasBackground ? Color.black : Color.white)
                            .frame(width: 40, height: 40)
                            .background(editingHasBackground ? Color.white : Color.white.opacity(0.2), in: Circle())
                    }

                    // Done Button
                    Button(L10n.Common.done) {
                        finishEditingText()
                    }
                    .font(DS.Font.headline)
                    .foregroundStyle(ColorTokens.accentPrimary)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(Color.white, in: Capsule())
                }
                .padding(.horizontal, DS.Padding.horizontal)
                .padding(.top, DS.Spacing.md)

                Spacer()

                // Center Live Editable Text
                TextField("", text: $editingText, axis: .vertical)
                    .focused($isFieldFocused)
                    .font(editingFontStyle.font)
                    .multilineTextAlignment(editingAlignment)
                    .foregroundStyle(editingColor)
                    .padding(.horizontal, editingHasBackground ? 16 : 8)
                    .padding(.vertical, editingHasBackground ? 10 : 4)
                    .background(
                        editingHasBackground ? editingColor.smartBadgeBackgroundColor : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .shadow(color: .black.opacity(editingHasBackground ? 0.35 : 0.7), radius: 6, x: 0, y: 2)
                    .padding(.horizontal, DS.Spacing.lg)

                Spacer()

                // Bottom Formatting Toolbars
                VStack(spacing: DS.Spacing.md) {
                    // Font Style Pills
                    HStack(spacing: DS.Spacing.sm) {
                        ForEach(TextFontStyle.allCases) { style in
                            Button {
                                editingFontStyle = style
                            } label: {
                                Text(style.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(editingFontStyle == style ? .bold : .regular)
                                    .foregroundStyle(editingFontStyle == style ? Color.black : Color.white)
                                    .padding(.horizontal, DS.Spacing.sm)
                                    .padding(.vertical, 6)
                                    .background(
                                        editingFontStyle == style ? Color.white : Color.white.opacity(0.2),
                                        in: Capsule()
                                    )
                            }
                        }
                    }

                    // Color Swatches
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Spacing.md) {
                            ForEach(0..<availableColors.count, id: \.self) { idx in
                                let col = availableColors[idx]
                                Button {
                                    editingColor = col
                                } label: {
                                    Circle()
                                        .fill(col)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: editingColor == col ? 3 : 1)
                                        )
                                        .shadow(radius: 2)
                                }
                            }
                        }
                        .padding(.horizontal, DS.Padding.horizontal)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.bottom, DS.Spacing.lg)
            }
        }
        .onAppear {
            isFieldFocused = true
        }
    }

    private var alignmentIconName: String {
        switch editingAlignment {
        case .leading: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .trailing: return "text.alignright"
        }
    }

    private func startEditingText(item: TextOverlayItem? = nil) {
        if let item {
            editingItemId = item.id
            editingText = item.text
            editingColor = item.color
            editingHasBackground = item.hasBackground
            editingFontStyle = item.fontStyle
            editingAlignment = item.alignment
        } else {
            editingItemId = nil
            editingText = ""
            editingColor = .white
            editingHasBackground = true
            editingFontStyle = .modern
            editingAlignment = .center
        }
        isEditingText = true
    }

    private func finishEditingText() {
        let trimmed = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let id = editingItemId {
            if trimmed.isEmpty {
                viewModel.texts.removeAll { $0.id == id }
            } else if let index = viewModel.texts.firstIndex(where: { $0.id == id }) {
                viewModel.texts[index].text = trimmed
                viewModel.texts[index].color = editingColor
                viewModel.texts[index].hasBackground = editingHasBackground
                viewModel.texts[index].fontStyle = editingFontStyle
                viewModel.texts[index].alignment = editingAlignment
            }
        } else if !trimmed.isEmpty {
            viewModel.texts.append(
                TextOverlayItem(
                    text: trimmed,
                    color: editingColor,
                    hasBackground: editingHasBackground,
                    fontStyle: editingFontStyle,
                    alignment: editingAlignment
                )
            )
        }
        isEditingText = false
    }

    private func showFilterToast(_ name: String) {
        filterAnnouncement = name
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if filterAnnouncement == name {
                withAnimation { filterAnnouncement = nil }
            }
        }
    }

    // MARK: - Simulator Mock Preview

    private var simulatorMockPreview: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemGray6), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: DS.Spacing.sm) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.6))
                Text("Story Camera Viewfinder")
                    .font(DS.Font.headline)
                    .foregroundStyle(.white)
                Text("Simulator Mock Mode: Nhấn nút chụp để tạo Story")
                    .font(DS.Font.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Permission Denied View

    private var permissionDeniedView: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: "camera.fill")
                .font(.system(size: DS.Size.iconHero))
                .foregroundStyle(.white.opacity(DS.Opacity.overlay))
            Text(L10n.StoryCamera.permissionTitle)
                .font(DS.Font.headline)
                .foregroundStyle(.white)
            Text(L10n.StoryCamera.permissionMessage)
                .font(DS.Font.subheadline)
                .foregroundStyle(.white.opacity(DS.Opacity.strong))
            Button(L10n.StoryCamera.openSettings) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(DS.Font.subheadlineBold)
            .foregroundStyle(ColorTokens.accentPrimary)
        }
    }

    private func isVideoData(_ data: Data) -> Bool {
        guard data.count >= 12 else { return false }
        let boxTypeBytes = [UInt8](data[4..<8])
        if let boxType = String(bytes: boxTypeBytes, encoding: .ascii) {
            return boxType == "ftyp" || boxType == "moov" || boxType == "wide"
        }
        return false
    }
}
