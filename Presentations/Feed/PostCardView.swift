//
//  PostCardView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import NukeUI

// MARK: - PostCardView

struct PostCardView: View {

    let post: Post
    let isVisible: Bool
    let scrollCoordinateSpaceName: String
    let viewportHeight: CGFloat
    let onLikeTapped: () -> Void
    let onSaveTapped: () -> Void
    let onVideoVisibilityChanged: (Bool) -> Void

    @State private var showHeart = false
    @State private var heartHideTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            imageSection
            actionsSection
            likesSection
            captionSection
            commentsSection
            timestampSection
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack(spacing: DS.Spacing.sm) {
            LazyImage(url: post.author.avatarURL) { state in
                if let image = state.image {
                    image.resizable()
                } else {
                    Circle().fill(ColorTokens.buttonSecondary)
                }
            }
            .frame(width: DS.Size.avatarCompact, height: DS.Size.avatarCompact)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                HStack(spacing: DS.Spacing.xxs) {
                    Text(post.author.username)
                        .font(DS.Font.username)

                    if post.author.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(DS.Font.caption)
                            .foregroundStyle(ColorTokens.verifiedBlue)
                    }
                }

                if let location = post.location {
                    Text(location.name)
                        .font(DS.Font.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if post.isSponsored {
                Text(L10n.Common.sponsored)
                    .font(DS.Font.caption2)
                    .foregroundStyle(.secondary)
            }

            Button {
                AppRouter.shared.present(sheet: .reportPost(postId: post.id))
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, DS.Padding.content)
        .padding(.vertical, DS.Spacing.xs)
    }

    private var imageSection: some View {
        ZStack {
            if let firstMedia = post.mediaItems.first {
                switch firstMedia.type {
                case .video:
                    ZStack {
                        // Video thumbnail as background (visible before video loads)
                        VideoThumbnailView(videoURL: firstMedia.url, thumbnailURL: firstMedia.thumbnailURL)
                            .aspectRatio(DS.Layout.postSquareAspectRatio, contentMode: .fill)

                        // Video player overlays thumbnail
                        FeedVideoPlayer(
                            url: firstMedia.url,
                            id: "post_video_\(post.id)",
                            isVisible: isVisible
                        )
                        .aspectRatio(DS.Layout.postSquareAspectRatio, contentMode: .fill)
                    }
                    .onGeometryChange(for: Bool.self) { geometry in
                        isVideoVisibleEnough(geometry)
                    } action: { _, isVisibleEnough in
                        onVideoVisibilityChanged(isVisibleEnough)
                    }

                case .image:
                    LazyImage(url: firstMedia.url) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(DS.Layout.postSquareAspectRatio, contentMode: .fill)
                        } else if state.error != nil {
                            ColorTokens.buttonSecondary
                                .aspectRatio(DS.Layout.postSquareAspectRatio, contentMode: .fill)
                                .overlay {
                                    Image(systemName: "photo")
                                        .foregroundStyle(.secondary)
                                }
                        } else {
                            skeletonMediaPlaceholder
                        }
                    }
                }
            }

            // Double-tap heart animation
            if showHeart {
                Image(systemName: "heart.fill")
                    .font(.system(size: DS.Size.avatarXLarge))
                    .foregroundStyle(.white)
                    .shadow(radius: DS.Shadow.radius)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            handleDoubleTap()
        }
    }

    /// Double-tap to like + show the big heart animation. Uses a single
    /// cancellable task so rapid double-taps don't stack multiple hide timers.
    private func handleDoubleTap() {
        if !post.isLiked {
            onLikeTapped()
        }
        withAnimation(DS.Animation.smooth) {
            showHeart = true
        }
        heartHideTask?.cancel()
        heartHideTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(DS.Duration.doubleTapHeart * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(DS.Animation.fast) {
                showHeart = false
            }
        }
    }

    private var actionsSection: some View {
        HStack(spacing: DS.Spacing.md) {
            Button { onLikeTapped() } label: {
                Image(systemName: post.isLiked ? "heart.fill" : "heart")
                    .font(DS.Font.title3)
                    .foregroundStyle(post.isLiked ? ColorTokens.likeRed : .primary)
            }

            Button {
                AppRouter.shared.push(.comments(postId: post.id))
            } label: {
                Image(systemName: "bubble.right")
                    .font(DS.Font.title3)
                    .foregroundStyle(.primary)
            }

            Button {
                AppRouter.shared.present(sheet: .sharePost(postId: post.id))
            } label: {
                Image(systemName: "paperplane")
                    .font(DS.Font.title3)
                    .foregroundStyle(.primary)
            }

            Spacer()

            Button {
                onSaveTapped()
            } label: {
                Image(systemName: post.isSaved ? "bookmark.fill" : "bookmark")
                    .font(DS.Font.title3)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, DS.Padding.content)
        .padding(.vertical, DS.Padding.inputBar)
    }

    private var likesSection: some View {
        Group {
            if post.likesCount > 0 {
                Text(L10n.Common.likesCount(post.likesCount))
                    .font(DS.Font.actionCount)
                    .padding(.horizontal, DS.Padding.content)
            }
        }
    }

    @ViewBuilder
    private var captionSection: some View {
        if let caption = post.caption, !caption.isEmpty {
            HStack(alignment: .top, spacing: DS.Spacing.xxs) {
                Text(post.author.username)
                    .font(DS.Font.username)
                +
                Text(" \(caption)")
                    .font(DS.Font.subheadline)
            }
            .lineLimit(2)
            .padding(.horizontal, DS.Padding.content)
            .padding(.top, DS.Spacing.xxs)
        }
    }

    @ViewBuilder
    private var commentsSection: some View {
        if post.commentsCount > 0 {
            Button {
                AppRouter.shared.push(.comments(postId: post.id))
            } label: {
                Text(L10n.Feed.viewAllComments(post.commentsCount))
                    .font(DS.Font.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DS.Padding.content)
            .padding(.top, DS.Spacing.xxs)
        }
    }

    private var timestampSection: some View {
        Text(post.createdAt.timeAgoDisplay())
            .font(DS.Font.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, DS.Padding.content)
            .padding(.top, DS.Spacing.xxs)
            .padding(.bottom, DS.Spacing.sm)
    }

    // MARK: - Skeleton Placeholder

    private var skeletonMediaPlaceholder: some View {
        ColorTokens.backgroundSubtler
            .aspectRatio(DS.Layout.postSquareAspectRatio, contentMode: .fill)
            .overlay {
                ShimmerView()
            }
    }

    private func isVideoVisibleEnough(_ geometry: GeometryProxy) -> Bool {
        let frame = geometry.frame(in: .named(scrollCoordinateSpaceName))
        let visibleTop = max(frame.minY, 0)
        let visibleBottom = min(frame.maxY, viewportHeight)
        let visibleHeight = max(0, visibleBottom - visibleTop)

        guard frame.height > 0 else { return false }
        return visibleHeight / frame.height > Constants.videoAutoplayVisibilityThreshold
    }
}

// MARK: - Date Extension

extension Date {

    /// Cached formatter for dates older than a week (avoids per-call allocation).
    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    func timeAgoDisplay() -> String {
        let seconds = Int(-timeIntervalSinceNow)
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        if seconds < 604800 { return "\(seconds / 86400)d ago" }
        return Date.monthDayFormatter.string(from: self)
    }
}

// MARK: - Constants

private enum Constants {
    static let videoAutoplayVisibilityThreshold: CGFloat = 0.5
}
