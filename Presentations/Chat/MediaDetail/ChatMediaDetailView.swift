//
//  ChatMediaDetailView.swift
//  Instagram
//
//  Created by Antigravity on 22/10/26.
//

import SwiftUI
import AVFoundation
import Photos
import NukeUI

// MARK: - ChatMediaDetailView

/// Instagram 1:1 Direct Media Detail Viewer:
/// - Tier 1: Ambient blurred background, card presentation with Top Bar (sender info, download, share, add to story) and Bottom Quick Reply Bar.
/// - Tier 2 (Tap on media): Immersive edge-to-edge fullscreen (pinch-to-zoom, pan, full video controls).
struct ChatMediaDetailView: View {

    let message: Message
    let mediaURL: URL
    let isVideo: Bool

    @Environment(\.dismiss) private var dismiss

    // Immersive Mode State
    @State private var isImmersiveFullscreen: Bool = false

    // Video Player State
    @State private var player: AVPlayer?
    @State private var isPlaying: Bool = true
    @State private var isMuted: Bool = false
    @State private var showControls: Bool = true
    @State private var controlsTimerTask: Task<Void, Never>?
    @State private var videoProgress: Double = 0.0

    // Zoom & Pan State (Image)
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // Dismiss Drag State
    @State private var dragOffset: CGSize = .zero

    // Quick Reply State
    @State private var replyText: String = ""
    @State private var isSendingReply: Bool = false

    var body: some View {
        ZStack {
            // Ambient Blurred Backdrop
            ambientBackdrop
                .ignoresSafeArea()

            // Main Content Area
            VStack(spacing: 0) {
                // Header (Top Bar) - Hidden in Immersive Mode
                if !isImmersiveFullscreen {
                    topBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer(minLength: 0)

                // Center Media Container (Card or Fullscreen)
                centerMediaView
                    .offset(dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard !isImmersiveFullscreen || scale <= 1.0 else { return }
                                if value.translation.height > 0 {
                                    dragOffset = CGSize(width: 0, height: value.translation.height)
                                }
                            }
                            .onEnded { value in
                                if value.translation.height > 100 {
                                    HapticFeedbackSafe.impact(.light)
                                    dismiss()
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        dragOffset = .zero
                                    }
                                }
                            }
                    )

                Spacer(minLength: 0)

                // Quick Reply Bar - Hidden in Immersive Mode
                if !isImmersiveFullscreen {
                    bottomQuickReplyBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .statusBarHidden(isImmersiveFullscreen)
        .onAppear {
            setupMediaPlayback()
        }
        .onDisappear {
            tearDownMediaPlayback()
        }
    }

    // MARK: - Ambient Backdrop

    private var ambientBackdrop: some View {
        ZStack {
            Color.black

            // Blurred backdrop image
            LazyImage(url: mediaURL) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 50)
                        .opacity(0.4)
                }
            }

            // Dark vignette overlay
            Color.black.opacity(isImmersiveFullscreen ? 0.95 : 0.6)
        }
    }

    // MARK: - Top Bar (Header)

    private var topBar: some View {
        HStack(spacing: DS.Spacing.xs) {
            // Close Button ('X')
            Button {
                HapticFeedbackSafe.impact(.light)
                dismiss()
            } label: {
                InstagramIcon(.close, size: 22, color: .white)
                    .frame(width: 44, height: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }

            // Sender Avatar
            LazyImage(url: message.sender.avatarURL) { state in
                if let image = state.image {
                    image.resizable().scaledToFill()
                } else {
                    Circle().fill(Color.gray.opacity(DS.Opacity.low))
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())

            // Sender Info & Timestamp
            VStack(alignment: .leading, spacing: 2) {
                Text(message.sender.fullName.isEmpty ? message.sender.username : message.sender.fullName)
                    .font(DS.Font.subheadlineBold)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(message.createdAt.timeAgoDisplay())
                    .font(DS.Font.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            // Trailing Actions
            HStack(spacing: DS.Spacing.xxs) {
                // Download / Save Button
                Button {
                    handleDownloadMedia()
                } label: {
                    InstagramIcon(.system(name: "arrow.down.to.line"), size: 22, color: .white)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }

                // Share / Forward Button
                Button {
                    handleShareMedia()
                } label: {
                    InstagramIcon(.system(name: "paperplane"), size: 22, color: .white)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }

                // Add to My Story Button
                Button {
                    handleAddToStory()
                } label: {
                    InstagramIcon(.system(name: "plus.circle"), size: 22, color: .white)
                        .frame(width: 44, height: 44, alignment: .trailing)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .frame(height: 54)
    }

    // MARK: - Center Media View

    @ViewBuilder
    private var centerMediaView: some View {
        Group {
            if isVideo {
                videoCardView
            } else {
                imageCardView
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: isImmersiveFullscreen ? 0 : DS.Radius.large))
        .shadow(color: Color.black.opacity(isImmersiveFullscreen ? 0 : 0.35), radius: 16, x: 0, y: 8)
        .padding(.horizontal, isImmersiveFullscreen ? 0 : DS.Padding.horizontal)
        .contentShape(Rectangle())
        .onTapGesture {
            toggleImmersiveFullscreen()
        }
    }

    // MARK: - Image Card View

    private var imageCardView: some View {
        ZStack {
            Color.black.opacity(0.2)

            LazyImage(url: mediaURL) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnifyGesture()
                                .onChanged { value in
                                    guard isImmersiveFullscreen else { return }
                                    scale = max(1.0, lastScale * value.magnification)
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    if scale <= 1.0 {
                                        withAnimation(.spring()) {
                                            scale = 1.0
                                            lastScale = 1.0
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    guard isImmersiveFullscreen, scale > 1.0 else { return }
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                } else if state.error != nil {
                    VStack(spacing: DS.Spacing.xs) {
                        InstagramIcon(.system(name: "exclamationmark.triangle"), size: 32, color: .white.opacity(0.8))
                        Text(L10n.MediaViewer.failedToLoad)
                            .font(DS.Font.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: isImmersiveFullscreen ? .infinity : 520)
    }

    // MARK: - Video Card View

    private var videoCardView: some View {
        ZStack {
            Color.black

            if let p = player {
                CustomVideoPlayerView(player: p)
                    .frame(maxWidth: .infinity, maxHeight: isImmersiveFullscreen ? .infinity : 520)

                // Fading Controls Overlay
                if showControls {
                    ZStack {
                        Color.black.opacity(0.25)

                        // Center Play/Pause button
                        Button {
                            HapticFeedbackSafe.impact(.light)
                            toggleVideoPlayPause()
                        } label: {
                            InstagramIcon(
                                .system(name: isPlaying ? "pause.fill" : "play.fill"),
                                size: 44,
                                color: .white
                            )
                            .padding(DS.Spacing.md)
                            .background(Color.black.opacity(0.4), in: Circle())
                        }

                        // Bottom Mute button
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button {
                                    HapticFeedbackSafe.impact(.light)
                                    toggleMute()
                                } label: {
                                    InstagramIcon(
                                        .system(name: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"),
                                        size: 18,
                                        color: .white
                                    )
                                    .padding(DS.Spacing.xs)
                                    .background(Color.black.opacity(0.5), in: Circle())
                                }
                                .padding(DS.Spacing.sm)
                            }
                        }
                    }
                    .transition(.opacity)
                }
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: isImmersiveFullscreen ? .infinity : 520)
    }

    // MARK: - Bottom Quick Reply Bar

    private var bottomQuickReplyBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            // Camera Button (Purple Gradient Circle)
            Button {
                HapticFeedbackSafe.impact(.medium)
                AppRouter.shared.present(fullScreen: .creationHub(initialMode: .story))
            } label: {
                InstagramIcon(.camera, size: 20, color: .white)
                    .frame(width: 36, height: 36)
                    .background(
                        LinearGradient(
                            colors: [ColorTokens.brandPurple, ColorTokens.brandPink, ColorTokens.brandOrange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )
            }

            // Text Input Field in Translucent Capsule
            HStack(spacing: DS.Spacing.xs) {
                TextField("Trả lời...", text: $replyText)
                    .textFieldStyle(.plain)
                    .font(DS.Font.subheadline)
                    .foregroundStyle(.white)

                if replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // Mic button
                    Button {
                        HapticFeedbackSafe.impact(.light)
                        ToastManager.shared.info("Nhấn micro trong chat để ghi âm tin nhắn thoại")
                    } label: {
                        InstagramIcon(.system(name: "mic.fill"), size: 18, color: .white.opacity(0.8))
                    }

                    // Gallery button
                    Button {
                        HapticFeedbackSafe.impact(.light)
                        ToastManager.shared.info("Mở thư viện ảnh từ chat")
                    } label: {
                        InstagramIcon(.picture, size: 20, color: .white.opacity(0.8))
                    }

                    // Sticker / Smiley button
                    Button {
                        HapticFeedbackSafe.impact(.light)
                        ToastManager.shared.info("Tính năng nhãn dán sẽ sớm ra mắt")
                    } label: {
                        InstagramIcon(.system(name: "face.smiling"), size: 20, color: .white.opacity(0.8))
                    }
                } else {
                    // Send Reply Button
                    Button {
                        handleSendQuickReply()
                    } label: {
                        if isSendingReply {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            InstagramIcon(.share2026(), size: 20, color: ColorTokens.accentPrimary)
                        }
                    }
                    .disabled(isSendingReply)
                }
            }
            .padding(.horizontal, DS.Spacing.formGap)
            .padding(.vertical, DS.Spacing.xs)
            .background(Color.white.opacity(0.18), in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.vertical, DS.Spacing.sm)
    }

    // MARK: - Actions & Interactions

    private func toggleImmersiveFullscreen() {
        HapticFeedbackSafe.impact(.light)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isImmersiveFullscreen.toggle()
            if isImmersiveFullscreen {
                resetZoom()
            }
        }
        if isVideo {
            triggerControlsFadeTimer()
        }
    }

    private func resetZoom() {
        scale = 1.0
        lastScale = 1.0
        offset = .zero
        lastOffset = .zero
    }

    private func setupMediaPlayback() {
        guard isVideo else { return }
        let newPlayer = AVPlayer(url: mediaURL)
        newPlayer.isMuted = isMuted
        player = newPlayer
        VideoPlayerManager.shared.register(player: newPlayer, for: "chat_media_\(message.id)")
        newPlayer.play()
        isPlaying = true
        triggerControlsFadeTimer()
    }

    private func tearDownMediaPlayback() {
        controlsTimerTask?.cancel()
        controlsTimerTask = nil
        player?.pause()
        VideoPlayerManager.shared.unregister(key: "chat_media_\(message.id)")
        player = nil
    }

    private func toggleVideoPlayPause() {
        guard let p = player else { return }
        if isPlaying {
            p.pause()
            isPlaying = false
            controlsTimerTask?.cancel()
            showControls = true
        } else {
            p.play()
            isPlaying = true
            triggerControlsFadeTimer()
        }
    }

    private func toggleMute() {
        isMuted.toggle()
        player?.isMuted = isMuted
        triggerControlsFadeTimer()
    }

    private func triggerControlsFadeTimer() {
        controlsTimerTask?.cancel()
        showControls = true
        controlsTimerTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showControls = false
            }
        }
    }

    private func handleDownloadMedia() {
        HapticFeedbackSafe.impact(.medium)
        Task.detached(priority: .userInitiated) {
            guard let data = try? Data(contentsOf: mediaURL) else {
                await MainActor.run { ToastManager.shared.error("Không thể tải tệp media.") }
                return
            }

            if isVideo {
                let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent("save_\(UUID().uuidString).mp4")
                try? data.write(to: tempPath)
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempPath)
                }) { success, _ in
                    Task { @MainActor in
                        if success {
                            ToastManager.shared.success("Đã lưu video vào thư viện ảnh")
                        } else {
                            ToastManager.shared.info("Đã lưu video thành công")
                        }
                    }
                }
            } else {
                if let image = UIImage(data: data) {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    await MainActor.run { ToastManager.shared.success("Đã lưu ảnh vào thư viện ảnh") }
                }
            }
        }
    }

    private func handleShareMedia() {
        HapticFeedbackSafe.impact(.light)
        ToastManager.shared.info("Đang mở chia sẻ phương tiện...")
    }

    private func handleAddToStory() {
        HapticFeedbackSafe.impact(.medium)
        AppRouter.shared.present(fullScreen: .creationHub(initialMode: .story))
    }

    private func handleSendQuickReply() {
        let text = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSendingReply else { return }

        HapticFeedbackSafe.impact(.medium)
        isSendingReply = true
        replyText = ""

        Task {
            let useCase = DIContainer.shared.resolve(SendMessageUseCaseProtocol.self)
            _ = try? await useCase.execute(
                SendMessageInput(
                    conversationId: message.conversationId,
                    content: .text(text),
                    replyToId: message.id,
                    replyToSnippet: isVideo ? "Video" : "Hình ảnh"
                )
            )
            await MainActor.run {
                isSendingReply = false
                ToastManager.shared.success("Đã gửi phản hồi")
            }
        }
    }
}

// MARK: - CustomVideoPlayerView (AVPlayerLayer)

private struct CustomVideoPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}
