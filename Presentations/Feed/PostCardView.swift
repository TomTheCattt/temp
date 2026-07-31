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
    let onLikeTapped: () -> Void

    @State private var showHeart = false

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
                // More options
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
                    FeedVideoPlayer(
                        url: firstMedia.url,
                        id: "post_video_\(post.id)",
                        isVisible: isVisible
                    )
                    .aspectRatio(DS.Layout.postSquareAspectRatio, contentMode: .fill)

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
                            ColorTokens.backgroundSecondary
                                .aspectRatio(DS.Layout.postSquareAspectRatio, contentMode: .fill)
                                .overlay { ProgressView() }
                        }
                    }
                }
            }

            // Double-tap heart animation
            if showHeart {
                Image(systemName: "heart.fill")
                    .font(.system(size: DS.Size.avatarXLarge))
                    .foregroundStyle(.white)
                    .shadow(radius: 10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            if !post.isLiked {
                onLikeTapped()
            }
            withAnimation(DS.Animation.smooth) {
                showHeart = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(DS.Animation.fast) {
                    showHeart = false
                }
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
                // Share
            } label: {
                Image(systemName: "paperplane")
                    .font(DS.Font.title3)
                    .foregroundStyle(.primary)
            }

            Spacer()

            Button {
                // Bookmark
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
                Text("\(post.likesCount) likes")
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
                Text("View all \(post.commentsCount) comments")
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
}

// MARK: - Date Extension

extension Date {
    func timeAgoDisplay() -> String {
        let seconds = Int(-timeIntervalSinceNow)
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        if seconds < 604800 { return "\(seconds / 86400)d ago" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
}
