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

    /// Timer for auto-advance (image items only).
    @State private var timer: Timer?

    /// Unique key to force StoryVideoPlayer re-creation when item changes.
    @State private var videoPlayerKey: String = UUID().uuidString

    init(viewModel: StoryViewerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                if let item = viewModel.currentItem {
                    storyContent(item, size: geometry.size)
                }

                // Tap areas
                tapOverlay(size: geometry.size)

                // Top overlay: progress bars + header
                VStack(spacing: 0) {
                    progressBars
                        .padding(.top, DS.Spacing.xs)
                    storyHeader
                    Spacer()
                }

                // Sticker overlay
                if let sticker = viewModel.currentItem?.sticker {
                    stickerOverlay(sticker)
                }

                // Bottom: reply bar
                VStack {
                    Spacer()
                    replyBar
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .onAppear { handleItemChange() }
        .onDisappear { stopTimer() }
        .onChange(of: viewModel.currentItemIndex) { _, _ in
            handleItemChange()
        }
        .onChange(of: viewModel.currentStoryIndex) { _, _ in
            handleItemChange()
        }
        .onChange(of: viewModel.isPaused) { _, paused in
            if paused {
                stopTimer()
            } else if viewModel.currentItem?.type == .image {
                startImageTimer()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                if !viewModel.isPaused {
                    if viewModel.currentItem?.type == .image {
                        startImageTimer()
                    }
                    // Video resumes via VideoPlayerManager.isPlaybackAllowed
                }
            case .inactive, .background:
                viewModel.pause()
                stopTimer()
            @unknown default:
                break
            }
        }
        .gesture(
            LongPressGesture(minimumDuration: 0.2)
                .onChanged { _ in viewModel.pause() }
                .onEnded { _ in viewModel.resume() }
        )
    }

    // MARK: - Story Content

    @ViewBuilder
    private func storyContent(_ item: StoryItem, size: CGSize) -> some View {
        switch item.type {
        case .image:
            AsyncImage(url: item.mediaURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .clipped()
                case .failure:
                    Color.gray
                default:
                    ProgressView()
                        .tint(.white)
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
            .frame(width: size.width, height: size.height)
            .clipped()
        }
    }

    // MARK: - Sticker Overlay

    @ViewBuilder
    private func stickerOverlay(_ sticker: StoryStickerInfo) -> some View {
        VStack {
            Spacer()
                .frame(height: 200) // Position sticker in the middle-upper area

            HStack {
                Spacer()
                stickerView(sticker)
                Spacer()
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func stickerView(_ sticker: StoryStickerInfo) -> some View {
        switch sticker.type {
        case .location:
            HStack(spacing: DS.Spacing.xxs) {
                Image(systemName: "location.fill")
                    .font(DS.Font.caption)
                Text(sticker.data ?? "")
                    .font(DS.Font.captionBold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.xs)
            .background(.ultraThinMaterial, in: Capsule())

        case .mention:
            Text(sticker.data ?? "")
                .font(DS.Font.subheadlineBold)
                .foregroundStyle(.white)
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xs)
                .background(.ultraThinMaterial, in: Capsule())

        case .music:
            HStack(spacing: DS.Spacing.xxs) {
                Image(systemName: "music.note")
                    .font(DS.Font.caption)
                Text(sticker.data ?? "")
                    .font(DS.Font.caption)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.xs)
            .background(.ultraThinMaterial, in: Capsule())

        case .poll:
            VStack(spacing: DS.Spacing.xs) {
                Text(sticker.data ?? "")
                    .font(DS.Font.subheadlineBold)
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
            .font(DS.Font.subheadlineBold)
            .foregroundStyle(.white)
            .frame(width: 80, height: 36)
            .background(color, in: RoundedRectangle(cornerRadius: DS.Radius.medium))
    }

    // MARK: - Progress Bars

    private var progressBars: some View {
        HStack(spacing: DS.Spacing.xxxs + 1) {
            ForEach(0..<viewModel.totalItemsInCurrentStory, id: \.self) { index in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(DS.Opacity.low))
                            .frame(height: DS.Size.progressBarHeight)

                        Capsule()
                            .fill(Color.white)
                            .frame(
                                width: progressWidth(for: index, totalWidth: geo.size.width),
                                height: DS.Size.progressBarHeight
                            )
                    }
                }
                .frame(height: DS.Size.progressBarHeight)
            }
        }
        .padding(.horizontal, DS.Spacing.xs)
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
        HStack(spacing: DS.Spacing.sm) {
            if let story = viewModel.currentStory {
                AsyncImage(url: story.author.avatarURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(DS.Opacity.overlay))
                }
                .frame(width: DS.Size.avatarCompact, height: DS.Size.avatarCompact)
                .clipShape(Circle())

                Text(story.author.username)
                    .font(DS.Font.username)
                    .foregroundStyle(.white)

                if let item = viewModel.currentItem {
                    Text(item.createdAt, style: .relative)
                        .font(DS.Font.caption)
                        .foregroundStyle(.white.opacity(DS.Opacity.medium))
                }
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(DS.Font.title3)
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, DS.Padding.content)
        .padding(.top, DS.Spacing.xs)
    }

    // MARK: - Tap Overlay

    @ViewBuilder
    private func tapOverlay(size: CGSize) -> some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: size.width * 0.3)
                .contentShape(Rectangle())
                .onTapGesture { viewModel.goToPrevious() }

            Color.clear
                .frame(width: size.width * 0.7)
                .contentShape(Rectangle())
                .onTapGesture {
                    advanceOrDismiss()
                }
        }
    }

    // MARK: - Reply Bar

    private var replyBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            TextField("Send message", text: .constant(""))
                .textFieldStyle(.plain)
                .font(DS.Font.subheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, DS.Padding.horizontal)
                .padding(.vertical, DS.Padding.inputBar)
                .background(
                    Capsule()
                        .stroke(Color.white.opacity(DS.Opacity.overlay), lineWidth: DS.Stroke.thin)
                )

            Button(action: {}) {
                Image(systemName: "heart")
                    .font(DS.Font.title)
                    .foregroundStyle(.white)
            }

            Button(action: {}) {
                Image(systemName: "paperplane")
                    .font(DS.Font.title)
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.bottom, DS.Spacing.xl)
    }

    // MARK: - Timer & Navigation

    /// Called whenever the current item changes. Sets up the correct playback mode.
    private func handleItemChange() {
        stopTimer()
        viewModel.itemProgress = 0
        videoPlayerKey = UUID().uuidString

        guard let item = viewModel.currentItem else { return }

        switch item.type {
        case .image:
            startImageTimer()
        case .video:
            // Video progress is tracked by StoryVideoPlayer via onProgressUpdate callback.
            // No timer needed — video drives its own progress.
            break
        }
    }

    /// Start the timer for image-based story items.
    private func startImageTimer() {
        stopTimer()
        guard let item = viewModel.currentItem, item.type == .image else { return }

        let duration = item.duration > 0 ? item.duration : DS.Duration.storyItem
        let interval = DS.Duration.storyTick

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                guard !viewModel.isPaused else { return }

                viewModel.itemProgress += interval / duration
                if viewModel.itemProgress >= 1.0 {
                    advanceOrDismiss()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// Advance to next item/story or dismiss if at the end.
    private func advanceOrDismiss() {
        if !viewModel.hasNextStory && viewModel.currentItemIndex >= viewModel.totalItemsInCurrentStory - 1 {
            dismiss()
        } else {
            viewModel.goToNext()
        }
    }
}
