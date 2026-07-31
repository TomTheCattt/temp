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

    var body: some View {
        GeometryReader { geometry in
            if viewModel.isLoading && viewModel.reels.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .ignoresSafeArea()
        .task {
            await viewModel.loadReels()
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
                AsyncImage(url: reel.thumbnailURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } placeholder: {
                    Color.black
                }

                // Video player overlays thumbnail when active
                if isActive {
                    ReelVideoPlayer(url: reel.videoURL, id: reel.id, isActive: isActive)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }

                // Play icon overlay when not active
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
