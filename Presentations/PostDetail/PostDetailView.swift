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
    @State private var currentMediaIndex: Int = 0

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
            .scrollDismissesKeyboard(.interactively)

            commentInputBar
        }
        .navigationTitle(L10n.Common.post)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isLoading && viewModel.post == nil {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage, viewModel.post == nil {
                ErrorStateView(
                    message: errorMessage,
                    retryAction: {
                        Task {
                            await viewModel.loadPost()
                            await viewModel.loadComments()
                        }
                    }
                )
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
                    Circle().fill(ColorTokens.backgroundSubtler)
                }
                .frame(width: DS.Size.avatarMedium, height: DS.Size.avatarMedium)
                .clipShape(Circle())
                .onTapGesture {
                    AppRouter.shared.push(.userProfile(userId: post.author.id))
                }

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

                Menu {
                    if post.author.id == SessionStore.shared.currentUserId {
                        Button {
                            AppRouter.shared.present(sheet: .editPost(postId: post.id))
                        } label: {
                            Label(L10n.EditPost.title, systemImage: "pencil")
                        }
                    }
                    Button(role: .destructive) {
                        AppRouter.shared.present(sheet: .reportPost(postId: post.id))
                    } label: {
                        Label(L10n.ReportPost.title, systemImage: "flag")
                    }
                } label: {
                    InstagramIcon(.options, size: DS.Size.iconDefault, color: .primary)
                }
            }
            .padding(.horizontal, DS.Padding.horizontal)

            // Media (Multi-Media Carousel or Single Media)
            PostMediaCarouselView(
                post: post,
                isVisible: true,
                aspectRatio: DS.Layout.postSquareAspectRatio,
                currentMediaIndex: $currentMediaIndex,
                onDoubleTap: {
                    Task { await viewModel.toggleLike() }
                }
            )

            // Actions bar
            HStack(spacing: DS.Spacing.md) {
                Button(action: { Task { await viewModel.toggleLike() } }) {
                    InstagramIcon(AppIcon.like(selected: post.isLiked), size: DS.Size.iconDefault, color: post.isLiked ? ColorTokens.likeRed : .primary)
                }

                Button(action: {}) {
                    InstagramIcon(AppIcon.comment, size: DS.Size.iconDefault, color: .primary)
                }

                Button(action: {}) {
                    InstagramIcon(AppIcon.share, size: DS.Size.iconDefault, color: .primary)
                }

                Spacer()

                Button(action: {}) {
                    InstagramIcon(AppIcon.save(selected: post.isSaved), size: DS.Size.iconDefault, color: .primary)
                }
            }
            .overlay {
                CarouselPageIndicator(
                    pageCount: post.mediaItems.count,
                    currentIndex: $currentMediaIndex
                )
            }
            .padding(.horizontal, DS.Padding.horizontal)

            // Likes
            Text(L10n.Common.likesCount(post.likesCount))
                .font(DS.Font.actionCount)
                .padding(.horizontal, DS.Padding.horizontal)

            // Caption
            if let caption = post.caption, !caption.isEmpty {
                HStack(alignment: .top, spacing: DS.Spacing.xxs) {
                    Text(post.author.username)
                        .font(DS.Font.subheadlineBold)
                    +
                    Text(" \(caption)")
                        .font(DS.Font.subheadline)
                }
                .padding(.horizontal, DS.Padding.horizontal)
            }

            // Timestamp
            Text(post.createdAt, style: .relative)
                .font(DS.Font.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, DS.Padding.horizontal)
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
            TextField(L10n.Comments.addComment, text: $commentText)
                .textFieldStyle(.plain)
                .font(DS.Font.subheadline)

            if !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(L10n.Common.post) {
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
                Circle().fill(ColorTokens.backgroundSubtler)
            }
            .frame(width: DS.Size.avatarCompact, height: DS.Size.avatarCompact)
            .clipShape(Circle())
            .onTapGesture {
                AppRouter.shared.push(.userProfile(userId: comment.author.id))
            }

            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                HStack(alignment: .top, spacing: DS.Spacing.xxs) {
                    Text(comment.author.username)
                        .font(DS.Font.bodyBold)
                    +
                    Text(" \(comment.text)")
                        .font(DS.Font.body)
                }

                HStack(spacing: DS.Spacing.sm) {
                    Text(comment.createdAt, style: .relative)
                    if comment.likesCount > 0 {
                        Text(L10n.Common.likesCount(comment.likesCount))
                    }
                    Button(L10n.Common.reply) {}
                }
                .font(DS.Font.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: {}) {
                InstagramIcon(AppIcon.like(selected: comment.isLiked), size: DS.Size.iconSmall, color: comment.isLiked ? ColorTokens.likeRed : .secondary)
            }
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.vertical, DS.Spacing.xxs)
    }
}
