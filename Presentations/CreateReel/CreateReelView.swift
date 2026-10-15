//
//  CreateReelView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import PhotosUI
import AVKit

@MainActor
struct CreateReelView: View {

    @State private var viewModel: CreateReelViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: CreateReelViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if viewModel.isShowingShareDetails {
                    shareDetailsScreen
                } else if viewModel.isShowingEditor {
                    editorScreen
                } else {
                    captureScreen
                }
            }
        }
        .task {
            await viewModel.setupCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .onChange(of: viewModel.isPublished) { _, published in
            if published {
                dismiss()
            }
        }
        .onChange(of: viewModel.videoPickerItem) { _, _ in
            Task {
                await viewModel.loadVideoFromPicker()
            }
        }
        .sheet(isPresented: $viewModel.isShowingTrimmer) {
            clipTrimmerSheet
        }
    }

    // MARK: - 1. Capture Screen

    private var captureScreen: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Viewfinder
            if viewModel.cameraService.isHardwareAvailable {
                CameraPreviewView(
                    session: viewModel.cameraService.session,
                    isHardwareAvailable: true
                )
                .ignoresSafeArea()
            } else {
                simulatorMockPreview
            }

            // Ghost Alignment Overlay
            if viewModel.isGhostEnabled, let ghost = viewModel.ghostFrame {
                Image(uiImage: ghost)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.35)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }

            // Countdown Overlay
            if viewModel.isCountingDown {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    Text("\(viewModel.countdownRemaining)")
                        .font(.system(size: 110, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .scaleEffect(1.1)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: viewModel.countdownRemaining)
                }
            }

            // Overlaid UI Controls
            VStack(spacing: 0) {
                // Top Multi-Segment Progress Bar
                topSegmentProgressBar
                    .padding(.top, DS.Spacing.xs)
                    .padding(.horizontal, DS.Spacing.sm)

                // Top Controls Bar
                topControlsBar
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.top, DS.Spacing.sm)

                Spacer()

                // Left Vertical Tools Toolbar
                HStack(alignment: .center) {
                    leftVerticalToolbar
                        .padding(.leading, DS.Spacing.md)

                    Spacer()
                }

                Spacer()

                // Bottom Record & Gallery Controls
                bottomCaptureControls
                    .padding(.horizontal, DS.Spacing.xl)
                    .padding(.bottom, DS.Spacing.xxl + 30) // Offset for bottom mode switcher in creation hub
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Top Multi-Segment Progress Bar

    private var topSegmentProgressBar: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let limit = viewModel.selectedDurationLimit.rawValue

            HStack(spacing: 3) {
                // Previously recorded segments
                ForEach(viewModel.recordedClips) { clip in
                    let segmentWidth = max(4.0, (clip.duration / limit) * totalWidth)
                    Capsule()
                        .fill(Color.white)
                        .frame(width: segmentWidth, height: 4)
                }

                // Currently active recording segment
                if viewModel.isRecording {
                    let liveWidth = max(4.0, (viewModel.currentClipDuration / limit) * totalWidth)
                    Capsule()
                        .fill(ColorTokens.accentPrimary)
                        .frame(width: liveWidth, height: 4)
                }

                // Remaining unfilled duration
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(height: 4)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Top Controls Bar

    private var topControlsBar: some View {
        HStack {
            // Dismiss
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.35), in: Circle())
            }

            Spacer()

            // Audio Selector Pill
            Button(action: {
                HUDManager.shared.showInfo(L10n.CreateReel.addAudio)
            }) {
                HStack(spacing: DS.Spacing.xxs) {
                    Image(systemName: "music.note")
                        .font(.system(size: 13, weight: .semibold))
                    Text(viewModel.selectedAudioName ?? L10n.CreateReel.addAudio)
                        .font(DS.Font.captionBold)
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.4), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
            }

            Spacer()

            // Flash Toggle
            Button(action: { viewModel.toggleFlash() }) {
                Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(viewModel.isFlashOn ? .yellow : .white)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.35), in: Circle())
            }
        }
    }

    // MARK: - Left Vertical Toolbar

    private var leftVerticalToolbar: some View {
        VStack(spacing: DS.Spacing.md) {
            // Duration Limit Tool (15s, 30s, 60s, 90s)
            toolPillButton(
                title: viewModel.selectedDurationLimit.title,
                icon: nil
            ) {
                viewModel.cycleDurationLimit()
            }

            // Speed Tool (.3x, .5x, 1x, 2x, 3x)
            toolPillButton(
                title: viewModel.selectedSpeed.title,
                icon: nil
            ) {
                viewModel.cycleSpeed()
            }

            // Timer Tool (3s, 10s, Off)
            toolPillButton(
                title: viewModel.selectedTimer == .off ? nil : viewModel.selectedTimer.title,
                icon: "timer"
            ) {
                viewModel.cycleTimer()
            }

            // Ghost / Alignment Tool (Available when clips recorded)
            if !viewModel.recordedClips.isEmpty {
                toolPillButton(
                    title: nil,
                    icon: "square.2.layers.3d",
                    isActive: viewModel.isGhostEnabled
                ) {
                    viewModel.toggleGhost()
                }
            }

            // Flip Camera Tool
            toolPillButton(
                title: nil,
                icon: "camera.rotate"
            ) {
                viewModel.toggleCamera()
            }
        }
        .padding(.vertical, DS.Spacing.xs)
        .padding(.horizontal, 6)
        .background(Color.black.opacity(0.3), in: Capsule())
    }

    private func toolPillButton(
        title: String?,
        icon: String?,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Group {
                if let title {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundStyle(isActive ? ColorTokens.accentPrimary : .white)
            .frame(width: 36, height: 36)
            .background(
                isActive ? Color.white.opacity(0.2) : Color.clear,
                in: Circle()
            )
        }
    }

    // MARK: - Bottom Capture Controls

    private var bottomCaptureControls: some View {
        let galleryThumb = viewModel.latestGalleryThumbnail
        return HStack(alignment: .center) {
            // Left: Gallery / PhotosPicker Button
            ZStack {
                PhotosPicker(
                    selection: $viewModel.videoPickerItem,
                    matching: .videos
                ) {
                    if let thumbnail = galleryThumb {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.thumbnailCard))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.thumbnailCard)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: DS.Radius.thumbnailCard)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(DS.Font.caption)
                                    .foregroundStyle(.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.thumbnailCard)
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                    }
                }

                // Delete Last Clip Button if clips exist
                if !viewModel.recordedClips.isEmpty && !viewModel.isRecording {
                    Button(action: {
                        viewModel.deleteLastClip()
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Color.black.opacity(0.6), in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                    }
                    .offset(x: 52)
                }
            }
            .frame(width: 80, alignment: .leading)

            Spacer()

            // Center: Reel Shutter / Record Button
            Button(action: {
                viewModel.triggerRecord()
            }) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 5)
                        .frame(width: 76, height: 76)

                    if viewModel.isRecording {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                            .frame(width: 28, height: 28)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.pink, Color.red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                    }
                }
                .scaleEffect(viewModel.isRecording ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
            }

            Spacer()

            // Right: Next / Proceed Button when clips exist
            Group {
                if !viewModel.recordedClips.isEmpty && !viewModel.isRecording {
                    Button(action: {
                        Task {
                            await viewModel.proceedToEditor()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(L10n.Common.next)
                                .font(.system(size: 14, weight: .bold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white, in: Capsule())
                        .overlay(
                            // Clip count badge
                            Text("\(viewModel.recordedClips.count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 18, height: 18)
                                .background(Color.red, in: Circle())
                                .offset(x: 8, y: -8),
                            alignment: .topTrailing
                        )
                    }
                } else {
                    Color.clear.frame(width: 80, height: 44)
                }
            }
            .frame(width: 80, alignment: .trailing)
        }
    }

    // MARK: - Simulator Mock Preview

    private var simulatorMockPreview: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.12), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: DS.Spacing.xs) {
                Image(systemName: "video.fill")
                    .font(.system(size: DS.Spacing.xxxl))
                    .foregroundStyle(ColorTokens.accentPrimary.opacity(0.8))
                Text("Reel Camera (Simulator)")
                    .font(DS.Font.headline)
                    .foregroundStyle(.white)
                Text("Nhấn nút tròn đỏ để ghi từng đoạn clip")
                    .font(DS.Font.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - 2. Editor Screen

    private var editorScreen: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Looping Merged Video Preview
            if let url = viewModel.finalVideoURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            // Editor Overlays
            VStack {
                // Top Action Bar
                HStack(spacing: DS.Spacing.md) {
                    Button(action: {
                        viewModel.isShowingEditor = false
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.black.opacity(0.4), in: Circle())
                    }

                    Spacer()

                    // Top editor tools
                    HStack(spacing: DS.Spacing.sm) {
                        editorToolButton(icon: "music.note") {
                            HUDManager.shared.showInfo(L10n.CreateReel.addAudio)
                        }
                        editorToolButton(icon: "character") {
                            HUDManager.shared.showInfo("Văn bản Aa")
                        }
                        editorToolButton(icon: "sparkles") {
                            HUDManager.shared.showInfo("Hiệu ứng")
                        }
                        editorToolButton(icon: "arrow.down.to.line") {
                            HUDManager.shared.showSuccess("Đã lưu vào cuộn camera")
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.top, DS.Spacing.sm)

                Spacer()

                // Bottom Bar: "Chỉnh sửa video" & "Tiếp"
                HStack(spacing: DS.Spacing.md) {
                    // Trimmer / Clips review button
                    Button(action: {
                        viewModel.isShowingTrimmer = true
                    }) {
                        HStack(spacing: DS.Spacing.xxs) {
                            Image(systemName: "film")
                            Text("Sửa các đoạn (\(viewModel.recordedClips.count))")
                                .font(DS.Font.captionBold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, DS.Spacing.md)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.2), in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                    }

                    Spacer()

                    // Next to Share Details
                    Button(action: {
                        viewModel.isShowingShareDetails = true
                    }) {
                        HStack(spacing: 6) {
                            Text(L10n.Common.next)
                                .font(.system(size: 15, weight: .bold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, DS.Spacing.xl)
                        .padding(.vertical, 11)
                        .background(ColorTokens.accentPrimary, in: Capsule())
                    }
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.bottom, DS.Spacing.xl)
            }
        }
        .navigationBarHidden(true)
    }

    private func editorToolButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Color.black.opacity(0.4), in: Circle())
        }
    }

    // MARK: - 3. Clip Trimmer Sheet

    private var clipTrimmerSheet: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.md) {
                Text("Quản lý các đoạn clip đã quay")
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, DS.Spacing.sm)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.sm) {
                        ForEach(Array(viewModel.recordedClips.enumerated()), id: \.element.id) { index, clip in
                            VStack(spacing: DS.Spacing.xs) {
                                ZStack(alignment: .topTrailing) {
                                    if let thumb = clip.thumbnail {
                                        Image(uiImage: thumb)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 90, height: 160)
                                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
                                    } else {
                                        RoundedRectangle(cornerRadius: DS.Radius.medium)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 90, height: 160)
                                    }

                                    // Delete clip button
                                    Button(action: {
                                        viewModel.deleteClip(at: index)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(.white, Color.red)
                                    }
                                    .padding(4)
                                }

                                Text(String(format: "%.1fs", clip.duration))
                                    .font(DS.Font.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, DS.Spacing.md)
                }
                .frame(height: 200)

                Spacer()
            }
            .navigationTitle("Đoạn clip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) {
                        viewModel.isShowingTrimmer = false
                        Task {
                            await viewModel.proceedToEditor()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - 4. Share Details Screen

    private var shareDetailsScreen: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    viewModel.isShowingShareDetails = false
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(ColorTokens.textPrimary)
                }

                Spacer()

                Text(L10n.CreateReel.title)
                    .font(DS.Font.headline)
                    .foregroundStyle(ColorTokens.textPrimary)

                Spacer()

                Color.clear.frame(width: 24, height: 24)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .background(ColorTokens.backgroundPrimary)

            Divider()

            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    // Preview Card & Caption
                    HStack(alignment: .top, spacing: DS.Spacing.md) {
                        // 9:16 Video Cover Card
                        ZStack(alignment: .bottom) {
                            if let cover = viewModel.coverImage {
                                Image(uiImage: cover)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
                            } else {
                                RoundedRectangle(cornerRadius: DS.Radius.medium)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 90, height: 140)
                            }

                            Text("Sửa ảnh bìa")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.vertical, 3)
                                .frame(maxWidth: .infinity)
                                .background(Color.black.opacity(0.6))
                                .clipShape(
                                    .rect(
                                        topLeadingRadius: 0,
                                        bottomLeadingRadius: DS.Radius.medium,
                                        bottomTrailingRadius: DS.Radius.medium,
                                        topTrailingRadius: 0
                                    )
                                )
                        }
                        .frame(width: 90, height: 140)

                        // Caption TextField
                        TextField(
                            "Viết chú thích hoặc thêm cuộc thăm dò ý kiến...",
                            text: $viewModel.caption,
                            axis: .vertical
                        )
                        .font(DS.Font.subheadline)
                        .lineLimit(4...7)
                        .padding(.top, DS.Spacing.xs)
                    }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.top, DS.Spacing.md)

                    Divider()

                    // Settings Rows (Also Share to Feed, Tag, Location)
                    VStack(spacing: 0) {
                        Toggle(isOn: $viewModel.alsoShareToFeed) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Cũng chia sẻ lên Bảng tin")
                                    .font(DS.Font.subheadline)
                                    .foregroundStyle(ColorTokens.textPrimary)
                                Text("Thước phim của bạn sẽ xuất hiện trên trang cá nhân và Bảng tin của người theo dõi.")
                                    .font(DS.Font.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(ColorTokens.accentPrimary)
                        .padding(.horizontal, DS.Spacing.md)
                        .padding(.vertical, DS.Spacing.sm)

                        Divider().padding(.leading, DS.Spacing.md)

                        shareOptionRow(icon: "person.badge.plus", title: "Gắn thẻ người khác") {
                            HUDManager.shared.showInfo("Gắn thẻ người khác")
                        }

                        Divider().padding(.leading, DS.Spacing.md)

                        shareOptionRow(icon: "mappin.and.ellipse", title: "Thêm vị trí") {
                            HUDManager.shared.showInfo("Thêm vị trí")
                        }

                        Divider().padding(.leading, DS.Spacing.md)

                        shareOptionRow(icon: "music.note", title: "Đổi tên âm thanh") {
                            HUDManager.shared.showInfo("Đổi tên âm thanh")
                        }
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(ColorTokens.backgroundPrimary)

            Divider()

            // Sticky Bottom Actions: Save Draft & Share Reel
            HStack(spacing: DS.Spacing.md) {
                Button(action: {
                    HUDManager.shared.showSuccess("Đã lưu bản nháp thước phim")
                    dismiss()
                }) {
                    Text("Lưu bản nháp")
                        .font(DS.Font.subheadlineBold)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.medium)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }

                Button(action: {
                    Task {
                        await viewModel.publish()
                    }
                }) {
                    Group {
                        if viewModel.isPublishing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(L10n.Common.share)
                                .font(DS.Font.subheadlineBold)
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(ColorTokens.accentPrimary, in: RoundedRectangle(cornerRadius: DS.Radius.medium))
                }
                .disabled(viewModel.isPublishing)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .background(ColorTokens.backgroundPrimary)
        }
        .navigationBarHidden(true)
    }

    private func shareOptionRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundStyle(ColorTokens.textPrimary)
                    .frame(width: 24)

                Text(title)
                    .font(DS.Font.subheadline)
                    .foregroundStyle(ColorTokens.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.md)
        }
    }
}
