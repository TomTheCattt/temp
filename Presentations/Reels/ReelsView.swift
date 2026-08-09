//
//  ReelsView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - ReelsView

struct ReelsView: View {

    @State private var viewModel: ReelsViewModel

    init(viewModel: ReelsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    @State private var selectedTabMode: Int = 0 // 0: Reels, 1: Following

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geometry in
                if viewModel.isLoading && viewModel.reels.isEmpty {
                    // Skeleton loading for reels
                    ReelSkeletonView()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.reels.enumerated()), id: \.element.id) { index, reel in
                                ReelItemView(
                                    reel: reel,
                                    isActive: index == viewModel.currentIndex,
                                    onLike: { Task { await viewModel.toggleLike(for: reel) } },
                                    onComment: { navigateToComments(reel) },
                                    onShare: {}
                                )
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .onAppear { viewModel.onReelAppear(at: index) }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                }
            }

            // Custom Navigation Bar for Reels (4 buttons)
            reelsNavigationBar
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadReels()
        }
    }

    // MARK: - Reels Navigation Bar (4 buttons: 1 leading, 2 center, 1 trailing)

    private var reelsNavigationBar: some View {
        VStack(spacing: 0) {
            // Status bar top safe area extension
            Color.clear
                .frame(height: DS.Size.navBarStatusBarHeight)

            HStack {
                // Button 1: Leading (Camera)
                Button {
                    AppRouter.shared.present(fullScreen: .camera)
                } label: {
                    Image(systemName: "camera")
                        .font(.title3)
                        .foregroundStyle(.white)
                }

                Spacer()

                // Buttons 2 & 3: Center (Reels / Following)
                HStack(spacing: DS.Spacing.md) {
                    Button {
                        selectedTabMode = 0
                    } label: {
                        Text(L10n.Tab.reels)
                            .font(DS.Font.title3)
                            .fontWeight(selectedTabMode == 0 ? .bold : .medium)
                            .foregroundStyle(selectedTabMode == 0 ? .white : .white.opacity(DS.Opacity.medium))
                    }

                    Button {
                        selectedTabMode = 1
                    } label: {
                        Text(L10n.Common.following)
                            .font(DS.Font.title3)
                            .fontWeight(selectedTabMode == 1 ? .bold : .medium)
                            .foregroundStyle(selectedTabMode == 1 ? .white : .white.opacity(DS.Opacity.medium))
                    }
                }

                Spacer()

                // Button 4: Trailing (Search)
                Button {
                    AppRouter.shared.switchTab(.explore)
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, DS.Padding.horizontal)
            .frame(height: DS.Size.buttonDefaultHeight)
            .padding(.bottom, DS.Spacing.xs)
        }
        .background {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.black.opacity(Constants.blackGradientTop),
                        Color.black.opacity(Constants.blackGradientMid),
                        Color.black.opacity(Constants.gradientStopClear)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Rectangle()
                    .fill(.ultraThinMaterial)
            }
            .mask(
                LinearGradient(
                    colors: [
                        Color.white.opacity(Constants.gradientStopFull),
                        Color.white.opacity(Constants.gradientStopHigh),
                        Color.white.opacity(Constants.gradientStopMid),
                        Color.white.opacity(Constants.gradientStopClear)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private func navigateToComments(_ reel: Reel) {
        // TODO: navigate to comments for reel
    }
}

// MARK: - ReelItemView

struct ReelItemView: View {

    let reel: Reel
    let isActive: Bool
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void

    /// Tab bar height (49) + home indicator (~34) = ~83pt on notch devices.
    /// Using a safe constant that looks good on all devices.
    private let tabBarBottomPadding: CGFloat = DS.Padding.bottomSafe + 49

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black

                // Thumbnail always visible as background (until video renders)
                VideoThumbnailView(videoURL: reel.videoURL, thumbnailURL: reel.thumbnailURL)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                // Video player always in hierarchy — controls playback via isActive
                ReelVideoPlayer(url: reel.videoURL, id: reel.id, isActive: isActive)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                // Dim overlay + play icon when not active
                if !isActive {
                    Color.black.opacity(DS.Opacity.low)
                    Image(systemName: "play.fill")
                        .font(.system(size: DS.Size.iconHero))
                        .foregroundStyle(.white.opacity(DS.Opacity.medium))
                }

                // Content overlay
                VStack {
                    Spacer()
                    HStack(alignment: .bottom, spacing: DS.Spacing.sm) {
                        reelInfo
                        actionButtons
                    }
                    .padding(.horizontal, DS.Padding.content)
                    .padding(.bottom, tabBarBottomPadding)
                }
            }
        }
        .clipped()
    }

    // MARK: - Reel Info (bottom-left)

    private var reelInfo: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            // Author
            HStack(spacing: DS.Spacing.xs) {
                AsyncImage(url: reel.author.avatarURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(DS.Opacity.overlay))
                }
                .frame(width: DS.Size.avatarCompact, height: DS.Size.avatarCompact)
                .clipShape(Circle())

                Text(reel.author.username)
                    .font(DS.Font.username)
                    .foregroundStyle(.white)

                Button(action: {}) {
                    Text(L10n.Common.follow)
                        .font(DS.Font.captionBold)
                        .padding(.horizontal, DS.Spacing.sm)
                        .padding(.vertical, DS.Spacing.xxs)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.small)
                                .stroke(Color.white, lineWidth: DS.Stroke.thin)
                        )
                        .foregroundStyle(.white)
                }
            }

            // Caption (truncated)
            if let caption = reel.caption, !caption.isEmpty {
                Text(caption)
                    .font(DS.Font.caption)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .frame(maxWidth: 250, alignment: .leading)
            }

            // Audio
            if let audio = reel.audioTrack {
                HStack(spacing: DS.Spacing.iconGap) {
                    Image(systemName: "music.note")
                        .font(DS.Font.caption2)
                    Text("\(audio.artistName) • \(audio.name)")
                        .font(DS.Font.caption2)
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action Buttons (right side)

    private var actionButtons: some View {
        VStack(spacing: DS.Spacing.lg) {
            // Like
            VStack(spacing: DS.Spacing.xxs) {
                Button(action: onLike) {
                    Image(systemName: reel.isLiked ? "heart.fill" : "heart")
                        .font(DS.Font.title)
                        .foregroundStyle(reel.isLiked ? ColorTokens.likeRed : .white)
                }
                Text(formatCount(reel.likesCount))
                    .font(DS.Font.caption2)
                    .foregroundStyle(.white)
            }

            // Comment
            VStack(spacing: DS.Spacing.xxs) {
                Button(action: onComment) {
                    Image(systemName: "bubble.right")
                        .font(DS.Font.title)
                        .foregroundStyle(.white)
                }
                Text(formatCount(reel.commentsCount))
                    .font(DS.Font.caption2)
                    .foregroundStyle(.white)
            }

            // Share
            VStack(spacing: DS.Spacing.xxs) {
                Button(action: onShare) {
                    Image(systemName: "paperplane")
                        .font(DS.Font.title)
                        .foregroundStyle(.white)
                }
                Text(formatCount(reel.sharesCount))
                    .font(DS.Font.caption2)
                    .foregroundStyle(.white)
            }

            // Save
            Button(action: {}) {
                Image(systemName: reel.isSaved ? "bookmark.fill" : "bookmark")
                    .font(DS.Font.title)
                    .foregroundStyle(.white)
            }

            // Audio disc
            if let audio = reel.audioTrack {
                AsyncImage(url: audio.coverURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray)
                }
                .frame(width: DS.Size.audioDisc, height: DS.Size.audioDisc)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(DS.Opacity.low), lineWidth: DS.Stroke.thin))
            }
        }
    }

    // MARK: - Helpers

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}

// MARK: - Constants

private enum Constants {
    static let gradientStopFull: Double = 0.95
    static let gradientStopHigh: Double = 0.70
    static let gradientStopMid: Double = 0.30
    static let gradientStopClear: Double = 0.00
    static let blackGradientTop: Double = 0.40
    static let blackGradientMid: Double = 0.20
}
