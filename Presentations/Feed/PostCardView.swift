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
    let onLikeTapped: () -> Void

    @State private var showHeart = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: Header
            headerSection

            // MARK: Image
            imageSection

            // MARK: Actions
            actionsSection

            // MARK: Likes
            likesSection

            // MARK: Caption
            captionSection

            // MARK: Comments
            commentsSection

            // MARK: Timestamp
            timestampSection
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack(spacing: 10) {
            // Avatar
            LazyImage(url: post.author.avatarURL) { state in
                if let image = state.image {
                    image.resizable()
                } else {
                    Circle().fill(Color(.systemGray5))
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(post.author.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if post.author.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }

                if let location = post.location {
                    Text(location.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if post.isSponsored {
                Text("Sponsored")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Button {
                // More options
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var imageSection: some View {
        ZStack {
            if let firstMedia = post.mediaItems.first {
                LazyImage(url: firstMedia.url) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                    } else if state.error != nil {
                        Color(.systemGray5)
                            .aspectRatio(1, contentMode: .fill)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    } else {
                        Color(.systemGray6)
                            .aspectRatio(1, contentMode: .fill)
                            .overlay { ProgressView() }
                    }
                }
            }

            // Double-tap heart animation
            if showHeart {
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
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
            withAnimation(.easeInOut(duration: 0.3)) {
                showHeart = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showHeart = false
                }
            }
        }
    }

    private var actionsSection: some View {
        HStack(spacing: 16) {
            Button { onLikeTapped() } label: {
                Image(systemName: post.isLiked ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(post.isLiked ? .red : .primary)
            }

            Button {
                AppRouter.shared.push(.comments(postId: post.id))
            } label: {
                Image(systemName: "bubble.right")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }

            Button {
                // Share
            } label: {
                Image(systemName: "paperplane")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }

            Spacer()

            Button {
                // Bookmark
            } label: {
                Image(systemName: post.isSaved ? "bookmark.fill" : "bookmark")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var likesSection: some View {
        Group {
            if post.likesCount > 0 {
                Text("\(post.likesCount) likes")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
            }
        }
    }

    @ViewBuilder
    private var captionSection: some View {
        if let caption = post.caption, !caption.isEmpty {
            HStack(alignment: .top, spacing: 4) {
                Text(post.author.username)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                +
                Text(" \(caption)")
                    .font(.subheadline)
            }
            .lineLimit(2)
            .padding(.horizontal, 12)
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var commentsSection: some View {
        if post.commentsCount > 0 {
            Button {
                AppRouter.shared.push(.comments(postId: post.id))
            } label: {
                Text("View all \(post.commentsCount) comments")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
        }
    }

    private var timestampSection: some View {
        Text(post.createdAt.timeAgoDisplay())
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .padding(.bottom, 12)
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
