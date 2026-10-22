//
//  StoryViewerView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - StoryViewerView

struct StoryViewerView: View {

    @State private var viewModel: StoryViewerViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var timer: Timer?
    @State private var videoPlayerKey: String = UUID().uuidString
    @State private var showDeleteConfirmation: Bool = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false

    private let contentCornerRadius: CGFloat = DS.Radius.large

    // MARK: - Ownership Check
    private var isCurrentStoryMine: Bool {
        guard let story = viewModel.currentStory else { return false }
        return story.author.id == SessionStore.shared.currentUserId
    }

    // MARK: - Drag to Dismiss Computations

    private var cardScale: CGFloat {
        max(0.85, 1.0 - (max(0, dragOffset.height) / 1000.0))
    }

    private var backgroundOpacity: Double {
        max(0.0, 1.0 - Double(max(0, dragOffset.height) / 300.0))
    }

    private var dynamicCornerRadius: CGFloat {
        min(32, contentCornerRadius + max(0, dragOffset.height) * 0.05)
    }

    init(viewModel: StoryViewerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        GeometryReader { geometry in

            ZStack {
                // Full-screen black background with interactive opacity fade
                Color.black.ignoresSafeArea()
                    .opacity(backgroundOpacity)

                VStack(spacing: 0) {
                    // MARK: Story Content Card (rounded)
                    ZStack(alignment: .top) {
                        // Media content
                        if viewModel.isLoading && viewModel.stories.isEmpty {
                            RoundedRectangle(cornerRadius: dynamicCornerRadius)
                                .fill(Color(.systemGray6).opacity(0.2))
                                .overlay { ProgressView().tint(.white) }
                                .frame(height: geometry.size.height - geometry.safeAreaInsets.top)
                        } else if let item = viewModel.currentItem {
                            storyContent(item, geometry: geometry)
                                .clipShape(RoundedRectangle(cornerRadius: dynamicCornerRadius))
                        }

                        // Tap overlay for prev/next (inside content area)
                        tapOverlay(size: geometry.size)
                            .clipShape(RoundedRectangle(cornerRadius: dynamicCornerRadius))

                        // Top controls: progress + header (inside content card)
                        VStack(spacing: DS.Spacing.xs) {
                            progressBars
                            storyHeader
                        }
                        .padding(.top, DS.Spacing.sm)
                        .padding(.horizontal, DS.Spacing.sm)

                        // Sticker (centered in content)
                        if let sticker = viewModel.currentItem?.sticker {
                            VStack {
                                Spacer()
                                stickerView(sticker)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, DS.Spacing.xxxs)

                    // MARK: Dynamic Bottom Bar (adapts whether viewing own story or other user's story)
                    Group {
                        if isCurrentStoryMine {
                            myStoryBottomBar
                        } else {
                            replyBar
                        }
                    }
                    .padding(.horizontal, DS.Padding.horizontal)
                    .padding(.top, DS.Spacing.sm)
                    .animation(.easeInOut(duration: 0.2), value: isCurrentStoryMine)
                }
                .offset(y: max(0, dragOffset.height))
                .scaleEffect(cardScale)
                .shadow(color: .black.opacity(isDragging ? 0.35 : 0), radius: 16, y: 8)
            }
            .gesture(
                LongPressGesture(minimumDuration: 0.2)
                    .onChanged { _ in
                        if !isDragging {
                            viewModel.pause()
                        }
                    }
                    .onEnded { _ in
                        if !isDragging {
                            viewModel.resume()
                        }
                    }
            )
            .simultaneousGesture(dragToDismissGesture(screenHeight: geometry.size.height))
        }
        .statusBarHidden()
        .presentationBackground(.clear)
        .task {
            await viewModel.loadStories()
            handleItemChange()
        }
        .onDisappear { stopTimer() }
        .onChange(of: viewModel.currentItemIndex) { _, _ in handleItemChange() }
        .onChange(of: viewModel.currentStoryIndex) { _, _ in handleItemChange() }
        .onChange(of: viewModel.isPaused) { _, paused in
            if paused { stopTimer() }
            else if viewModel.currentItem?.type == .image { startImageTimer() }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                if !viewModel.isPaused, viewModel.currentItem?.type == .image {
                    startImageTimer()
                }
            case .inactive, .background:
                viewModel.pause()
                stopTimer()
            @unknown default: break
            }
        }
        .confirmationDialog(L10n.Story.deleteTitle, isPresented: $showDeleteConfirmation) {
            Button(L10n.Common.delete, role: .destructive) {
                Task {
                    let shouldDismiss = await viewModel.deleteCurrentStory()
                    if shouldDismiss {
                        dismiss()
                    }
                }
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Story.deleteMessage)
        }
        .onChange(of: showDeleteConfirmation) { _, isShowing in
            if isShowing {
                viewModel.pause()
            } else {
                viewModel.resume()
            }
        }
    }

    // MARK: - Story Content

    @ViewBuilder
    private func storyContent(_ item: StoryItem, geometry: GeometryProxy) -> some View {
        let contentWidth = geometry.size.width - DS.Spacing.xxxs * 2
        let contentHeight = geometry.size.height
            - geometry.safeAreaInsets.top
//            - 60 // reply bar area
//            - geometry.safeAreaInsets.bottom

        switch item.type {
        case .image:
            AsyncImage(url: item.mediaURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: contentWidth, height: contentHeight)
                case .failure:
                    Color(.systemGray5)
                        .frame(width: contentWidth, height: contentHeight)
                default:
                    Color(.systemGray6).opacity(0.3)
                        .frame(width: contentWidth, height: contentHeight)
                        .overlay { ProgressView().tint(.white) }
                }
            }

        case .video:
            StoryVideoPlayer(
                url: item.mediaURL,
                id: videoPlayerKey,
                isActive: true,
                isPaused: viewModel.isPaused,
                onProgressUpdate: { progress in
                    viewModel.itemProgress = progress
                },
                onVideoEnded: {
                    advanceOrDismiss()
                }
            )
            .id(videoPlayerKey)
            .frame(width: contentWidth, height: contentHeight)
        }
    }

    // MARK: - Progress Bars

    private var progressBars: some View {
        HStack(spacing: 2) {
            ForEach(0..<viewModel.totalItemsInCurrentStory, id: \.self) { index in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.35))
                            .frame(height: 2)

                        Capsule()
                            .fill(Color.white)
                            .frame(
                                width: progressWidth(for: index, totalWidth: geo.size.width),
                                height: 2
                            )
                    }
                }
                .frame(height: 2)
            }
        }
    }

    private func progressWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        if index < viewModel.currentItemIndex {
            return totalWidth
        } else if index == viewModel.currentItemIndex {
            return totalWidth * viewModel.itemProgress
        } else {
            return 0
        }
    }

    // MARK: - Header

    private var storyHeader: some View {
        HStack(spacing: DS.Spacing.xs) {
            if let story = viewModel.currentStory {
                if isCurrentStoryMine {
                    // Current User's Own Story Header
                    AsyncImage(url: story.author.avatarURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(DS.Opacity.muted))
                    }
                    .frame(width: DS.Size.avatarCompact, height: DS.Size.avatarCompact)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(DS.Opacity.medium), lineWidth: DS.Stroke.thin))

                    Text(L10n.Story.yourStory)
                        .font(DS.Font.username)
                        .foregroundStyle(.white)

                    if let item = viewModel.currentItem {
                        Text(item.createdAt, style: .relative)
                            .font(DS.Font.caption2)
                            .foregroundStyle(.white.opacity(DS.Opacity.medium))
                    }

                    Spacer()

                    // Add story (Camera) button
                    Button {
                        viewModel.pause()
                        dismiss()
                        AppRouter.shared.present(fullScreen: .storyCamera)
                    } label: {
                        InstagramIcon(.camera, size: DS.FontSize.overlayMedium, color: .white)
                            .frame(width: DS.Size.buttonDefaultHeight, height: DS.Size.buttonDefaultHeight)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)

                    // Close button
                    Button { dismiss() } label: {
                        InstagramIcon(.close, size: DS.FontSize.overlayLarge, color: .white)
                            .frame(width: DS.Size.buttonDefaultHeight, height: DS.Size.buttonDefaultHeight)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                } else {
                    // Other User's Story Header
                    AsyncImage(url: story.author.avatarURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(DS.Opacity.muted))
                    }
                    .frame(width: DS.Size.avatarCompact, height: DS.Size.avatarCompact)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(DS.Opacity.medium), lineWidth: DS.Stroke.thin))
                    .onTapGesture {
                        viewModel.pause()
                        dismiss()
                        AppRouter.shared.push(.userProfile(userId: story.author.id))
                    }

                    Text(story.author.username)
                        .font(DS.Font.username)
                        .foregroundStyle(.white)
                        .onTapGesture {
                            viewModel.pause()
                            dismiss()
                            AppRouter.shared.push(.userProfile(userId: story.author.id))
                        }

                    if let item = viewModel.currentItem {
                        Text(item.createdAt, style: .relative)
                            .font(DS.Font.caption2)
                            .foregroundStyle(.white.opacity(DS.Opacity.medium))
                    }

                    Spacer()

                    // Close button
                    Button { dismiss() } label: {
                        InstagramIcon(.close, size: DS.FontSize.overlayLarge, color: .white)
                            .frame(width: DS.Size.buttonDefaultHeight, height: DS.Size.buttonDefaultHeight)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Tap Overlay

    @ViewBuilder
    private func tapOverlay(size: CGSize) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture { viewModel.goToPrevious() }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture { advanceOrDismiss() }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - My Story Bottom Bar

    @ViewBuilder
    private var myStoryBottomBar: some View {
        HStack(spacing: DS.Spacing.md) {
            // Viewers info (left side)
            Button(action: {}) {
                HStack(spacing: DS.Spacing.xs) {
                    // Stacked viewer avatars
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray4))
                            .frame(width: DS.Size.viewerAvatar, height: DS.Size.viewerAvatar)
                        Circle()
                            .fill(Color(.systemGray3))
                            .frame(width: DS.Size.viewerAvatar, height: DS.Size.viewerAvatar)
                            .offset(x: DS.Size.iconXSmall)
                    }
                    .frame(width: DS.Size.viewerAvatarCluster)

                    Text(L10n.Story.viewers)
                        .font(.system(size: DS.FontSize.overlayBody))
                        .foregroundStyle(.white)
                }
            }

            // Close Friends indicator
            Button(action: {}) {
                HStack(spacing: DS.Spacing.xxs) {
                    InstagramIcon(.system(name: "star.circle.fill"), size: DS.FontSize.overlayMedium, color: ColorTokens.success)
                    Text(L10n.Story.closeFriends)
                        .font(.system(size: DS.FontSize.overlayBody))
                        .foregroundStyle(.white)
                }
            }

            Spacer()

            // Delete button
            Button {
                showDeleteConfirmation = true
            } label: {
                InstagramIcon(.system(name: "trash"), size: DS.FontSize.overlayXLarge, color: .white)
                    .frame(width: DS.Size.buttonDefaultHeight, height: DS.Size.buttonDefaultHeight)
                    .contentShape(Circle())
            }

            // Options button
            Button(action: {}) {
                InstagramIcon(.options, size: DS.FontSize.overlayXLarge, color: .white)
                    .frame(width: DS.Size.buttonDefaultHeight, height: DS.Size.buttonDefaultHeight)
                    .contentShape(Circle())
            }
        }
    }

    // MARK: - Reply Bar

    @ViewBuilder
    private var replyBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            TextField("Send message", text: .constant(""))
                .textFieldStyle(.plain)
                .font(DS.Font.subheadline)
                .foregroundStyle(ColorTokens.textTertiary)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .background(
                    Capsule()
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )

            Button(action: {}) {
                InstagramIcon(.like(), size: 24, color: .white)
            }

            Button(action: {}) {
                InstagramIcon(.share2026(), size: 22, color: .white)
            }
        }
    }

    // MARK: - Sticker
 
    @ViewBuilder
    private func stickerView(_ sticker: StoryStickerInfo) -> some View {
        switch sticker.type {
        case .location:
            InstagramStickerView(.location, height: 36)

        case .mention:
            InstagramStickerView(.mention, height: 36)

        case .link:
            InstagramStickerView(.link, height: 36)

        case .music:
            HStack(spacing: DS.Spacing.xxs) {
                InstagramIcon(.system(name: "music.note"), size: 11, color: .white)
                Text(sticker.data ?? "")
                    .font(.system(size: 12))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.xs)
            .background(.ultraThinMaterial, in: Capsule())

        case .poll:
            VStack(spacing: DS.Spacing.xs) {
                Text(sticker.data ?? "")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                HStack(spacing: DS.Spacing.sm) {
                    pollButton(text: "Yes", color: ColorTokens.accentPrimary)
                    pollButton(text: "No", color: ColorTokens.destructive)
                }
            }
            .padding(DS.Spacing.md)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.large))

        default:
            EmptyView()
        }
    }

    private func pollButton(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 80, height: 36)
            .background(color, in: RoundedRectangle(cornerRadius: DS.Radius.medium))
    }

    // MARK: - Timer & Navigation

    private func handleItemChange() {
        stopTimer()
        viewModel.itemProgress = 0
        videoPlayerKey = UUID().uuidString

        guard let item = viewModel.currentItem else { return }
        if item.type == .image { startImageTimer() }
    }

    private func startImageTimer() {
        stopTimer()
        guard let item = viewModel.currentItem, item.type == .image else { return }

        let duration = item.duration > 0 ? item.duration : DS.Duration.storyItem
        let interval = DS.Duration.storyTick

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                guard !viewModel.isPaused else { return }
                viewModel.itemProgress += interval / duration
                if viewModel.itemProgress >= 1.0 { advanceOrDismiss() }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func advanceOrDismiss() {
        if !viewModel.hasNextStory && viewModel.currentItemIndex >= viewModel.totalItemsInCurrentStory - 1 {
            dismiss()
        } else {
            viewModel.goToNext()
        }
    }

    // MARK: - Drag to Dismiss Gesture

    private func dragToDismissGesture(screenHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                // Only handle downward drag (downward dominant)
                guard value.translation.height > 0,
                      value.translation.height > abs(value.translation.width) * 0.5 else {
                    return
                }

                if !isDragging {
                    isDragging = true
                    viewModel.pause()
                }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard isDragging else { return }

                let shouldDismiss = value.translation.height > 100
                    || value.predictedEndTranslation.height > 200

                if shouldDismiss {
                    withAnimation(.easeOut(duration: 0.2)) {
                        dragOffset = CGSize(width: 0, height: screenHeight)
                    }
                    dismiss()
                } else {
                    withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.8)) {
                        dragOffset = .zero
                        isDragging = false
                    }
                    viewModel.resume()
                }
            }
    }
}
