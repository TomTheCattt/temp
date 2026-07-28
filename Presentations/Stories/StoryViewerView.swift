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

    /// Timer for auto-advance.
    @State private var timer: Timer?

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

                // Bottom: reply bar
                VStack {
                    Spacer()
                    replyBar
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
        .onChange(of: viewModel.isPaused) { _, paused in
            if paused { stopTimer() } else { startTimer() }
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
            ZStack {
                Color.black
                Image(systemName: "play.circle.fill")
                    .font(.system(size: DS.Size.iconJumbo))
                    .foregroundStyle(.white.opacity(DS.Opacity.medium))
            }
        }
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
                    if !viewModel.hasNextStory && viewModel.currentItemIndex >= viewModel.totalItemsInCurrentStory - 1 {
                        dismiss()
                    } else {
                        viewModel.goToNext()
                    }
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

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        let duration = viewModel.currentItem?.duration ?? DS.Duration.storyItem
        let interval = DS.Duration.storyTick

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                guard !viewModel.isPaused else { return }

                viewModel.itemProgress += interval / duration
                if viewModel.itemProgress >= 1.0 {
                    if !viewModel.hasNextStory && viewModel.currentItemIndex >= viewModel.totalItemsInCurrentStory - 1 {
                        dismiss()
                    } else {
                        viewModel.goToNext()
                    }
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
