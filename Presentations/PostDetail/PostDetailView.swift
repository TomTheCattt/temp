//
//  PostDetailView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - PostDetailView

struct PostDetailView: View {

    @State private var viewModel: PostDetailViewModel
    @State private var commentText = ""

    init(viewModel: PostDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    if let post = viewModel.post {
                        postContent(post)
                        commentsSection
                    }
                }
            }
            .refreshable {
                await viewModel.loadPost()
                await viewModel.loadComments()
            }

            commentInputBar
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isLoading && viewModel.post == nil {
                ProgressView()
            }
        }
        .task {
            await viewModel.loadPost()
            await viewModel.loadComments()
        }
    }

    // MARK: - Post Content

    @ViewBuilder
    private func postContent(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            // Author header
            HStack(spacing: DS.Spacing.sm) {
                AsyncImage(url: post.author.avatarURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(DS.Opacity.low))
                }
                .frame(width: DS.Size.avatarMedium, height: DS.Size.avatarMedium)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                    Text(post.author.username)
                        .font(DS.Font.username)
                    if let location = post.location {
                        Text(location.name)
                            .font(DS.Font.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, DS.Padding.horizontal)

            // Media (simplified: first image)
            if let firstMedia = post.mediaItems.first {
                AsyncImage(url: firstMedia.url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(DS.Layout.postSquareAspectRatio, contentMode: .fit)
                }
                .frame(maxWidth: .infinity)
            }

            // Actions bar
            HStack(spacing: DS.Spacing.md) {
                Button(action: { Task { await viewModel.toggleLike() } }) {
                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(post.isLiked ? ColorTokens.likeRed : .primary)
                }

                Button(action: {}) {
                    Image(systemName: "bubble.right")
                        .foregroundStyle(.primary)
                }

                Button(action: {}) {
                    Image(systemName: "paperplane")
                        .foregroundStyle(.primary)
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: post.isSaved ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(.primary)
                }
            }
            .font(DS.Font.title3)
            .padding(.horizontal, DS.Padding.horizontal)

            // Likes
            Text("\(post.likesCount) likes")
                .font(DS.Font.actionCount)
                .padding(.horizontal, DS.Padding.horizontal)

            // Caption
            if let caption = post.caption, !caption.isEmpty {
                HStack(alignment: .top, spacing: DS.Spacing.xxs) {
                    Text(post.author.username).fontWeight(.semibold) +
                    Text(" \(caption)")
                }
                .font(DS.Font.subheadline)
                .padding(.horizontal, DS.Padding.horizontal)
            }

            // Timestamp
            Text(post.createdAt, style: .relative)
                .font(DS.Font.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, DS.Padding.horizontal)

            Divider()
                .padding(.top, DS.Spacing.xs)
        }
    }

    // MARK: - Comments Section

    @ViewBuilder
    private var commentsSection: some View {
        if viewModel.isLoadingComments {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding()
        } else {
            ForEach(viewModel.comments) { comment in
                CommentRowView(comment: comment)
            }
        }
    }

    // MARK: - Comment Input Bar

    private var commentInputBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            TextField("Add a comment...", text: $commentText)
                .textFieldStyle(.plain)
                .font(DS.Font.subheadline)

            if !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button("Post") {
                    let text = commentText
                    commentText = ""
                    Task { await viewModel.addComment(text: text) }
                }
                .font(DS.Font.subheadlineBold)
                .foregroundStyle(ColorTokens.accentPrimary)
            }
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.vertical, DS.Padding.inputBar)
        .overlay(alignment: .top) { Divider() }
    }
}

// MARK: - CommentRowView

struct CommentRowView: View {

    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.sm) {
            AsyncImage(url: comment.author.avatarURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(Color.gray.opacity(DS.Opacity.low))
            }
            .frame(width: DS.Size.avatarCompact, height: DS.Size.avatarCompact)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                HStack(alignment: .top, spacing: DS.Spacing.xxs) {
                    Text(comment.author.username).fontWeight(.semibold) +
                    Text(" \(comment.text)")
                }
                .font(DS.Font.commentText)

                HStack(spacing: DS.Spacing.sm) {
                    Text(comment.createdAt, style: .relative)
                    if comment.likesCount > 0 {
                        Text("\(comment.likesCount) likes")
                    }
                    Button("Reply") {}
                }
                .font(DS.Font.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                    .font(DS.Font.caption)
                    .foregroundStyle(comment.isLiked ? ColorTokens.likeRed : .secondary)
            }
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.vertical, DS.Spacing.xxs)
    }
}
