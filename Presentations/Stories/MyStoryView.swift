//
//  MyStoryView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI

// MARK: - MyStoryView

/// Story viewer for the current user's own stories.
/// Differs from StoryViewerView:
/// - Bottom bar shows viewers count, close friends indicator, delete & share actions
/// - No reply bar (you don't reply to yourself)
/// - Shows viewer avatars at bottom-left
struct MyStoryView: View {

    @State private var viewModel: StoryViewerViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var timer: Timer?
    @State private var videoPlayerKey: String = UUID().uuidString
    @State private var showDeleteConfirmation = false

    private let contentCornerRadius: CGFloat = 12

    init(viewModel: StoryViewerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            let topPadding = geometry.safeAreaInsets.top + DS.Spacing.xxs
            let bottomPadding = geometry.safeAreaInsets.bottom

            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: Story Content Card (rounded)
                    ZStack(alignment: .top) {
                        // Media content
                        if viewModel.isLoading && viewModel.stories.isEmpty {
                            RoundedRectangle(cornerRadius: contentCornerRadius)
                                .fill(Color(.systemGray6).opacity(0.2))
                                .overlay { ProgressView().tint(.white) }
                        } else if let item = viewModel.currentItem {
                            storyContent(item, geometry: geometry)
                                .clipShape(RoundedRectangle(cornerRadius: contentCornerRadius))
                        }

                        // Tap overlay
                        tapOverlay(size: geometry.size)
                            .clipShape(RoundedRectangle(cornerRadius: contentCornerRadius))

                        // Top controls: progress + header
                        VStack(spacing: DS.Spacing.xs) {
                            progressBars
                            storyHeader
                        }
                        .padding(.top, DS.Spacing.sm)
                        .padding(.horizontal, DS.Spacing.sm)

                        // Sticker
                        if let sticker = viewModel.currentItem?.sticker {
                            VStack {
                                Spacer()
                                stickerView(sticker)
                                Spacer()
                            }
                        }
                    }
//                    .padding(.top, topPadding)
                    .padding(.horizontal, DS.Spacing.xxxs)

                    // MARK: Bottom Bar (My Story actions)
                    myStoryBottomBar
                        .padding(.horizontal, DS.Padding.horizontal)
                        .padding(.top, DS.Spacing.sm)
//                        .padding(.bottom, max(bottomPadding, DS.Spacing.sm))
                }
            }
        }
//        .ignoresSafeArea()
        .statusBarHidden()
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
        .gesture(
            LongPressGesture(minimumDuration: 0.2)
                .onChanged { _ in viewModel.pause() }
                .onEnded { _ in viewModel.resume() }
        )
        .confirmationDialog("Delete Story", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                // TODO: Delete story item
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this story?")
        }
    }

    // MARK: - My Story Bottom Bar

    private var myStoryBottomBar: some View {
        HStack(spacing: DS.Spacing.md) {
            // Viewers info (left side)
            Button(action: {}) {
                HStack(spacing: DS.Spacing.xs) {
                    // Stacked viewer avatars
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray4))
                            .frame(width: 24, height: 24)
                        Circle()
                            .fill(Color(.systemGray3))
                            .frame(width: 24, height: 24)
                            .offset(x: 12)
                    }
                    .frame(width: 36)

                    Text("Viewers")
                        .font(.system(size: 13))
                        .foregroundStyle(.white)
                }
            }

            // Close Friends indicator
            Button(action: {}) {
                HStack(spacing: DS.Spacing.xxs) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.green)
                    Text("Close Friends")
                        .font(.system(size: 13))
                        .foregroundStyle(.white)
                }
            }

            Spacer()

            // Delete button
            Button {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }

            // Share button
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
        }
    }

    // MARK: - Story Content

    @ViewBuilder
    private func storyContent(_ item: StoryItem, geometry: GeometryProxy) -> some View {
        let contentWidth = geometry.size.width - DS.Spacing.xxxs * 2
        let contentHeight = geometry.size.height
            - geometry.safeAreaInsets.top
//            - 60
            - geometry.safeAreaInsets.bottom

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
        if index < viewModel.currentItemIndex { return totalWidth }
        else if index == viewModel.currentItemIndex { return totalWidth * viewModel.itemProgress }
        else { return 0 }
    }

    // MARK: - Header

    private var storyHeader: some View {
        HStack(spacing: DS.Spacing.xs) {
            if let story = viewModel.currentStory {
                AsyncImage(url: story.author.avatarURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.4))
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))

                Text("Your Story")
                    .font(DS.Font.username)
                    .foregroundStyle(.white)

                if let item = viewModel.currentItem {
                    Text(item.createdAt, style: .relative)
                        .font(DS.Font.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
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
                .frame(width: size.width * 0.3)

            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture { advanceOrDismiss() }
        }
    }

    // MARK: - Sticker

    @ViewBuilder
    private func stickerView(_ sticker: StoryStickerInfo) -> some View {
        switch sticker.type {
        case .location:
            HStack(spacing: DS.Spacing.xxs) {
                Image(systemName: "location.fill")
                    .font(.system(size: 11))
                Text(sticker.data ?? "")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.xs)
            .background(.ultraThinMaterial, in: Capsule())

        case .mention:
            Text(sticker.data ?? "")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xs)
                .background(.ultraThinMaterial, in: Capsule())

        case .music:
            HStack(spacing: DS.Spacing.xxs) {
                Image(systemName: "music.note")
                    .font(.system(size: 11))
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
                    Text("Yes")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 36)
                        .background(ColorTokens.accentPrimary, in: RoundedRectangle(cornerRadius: DS.Radius.medium))
                    Text("No")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 36)
                        .background(ColorTokens.destructive, in: RoundedRectangle(cornerRadius: DS.Radius.medium))
                }
            }
            .padding(DS.Spacing.md)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.large))

        default:
            EmptyView()
        }
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
}
