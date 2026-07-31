//
//  CommentsView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - CommentsView

struct CommentsView: View {

    @State private var viewModel: CommentsViewModel
    @State private var commentText = ""
    @FocusState private var isInputFocused: Bool

    init(viewModel: CommentsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Comments list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if viewModel.isLoading && viewModel.comments.isEmpty {
                        loadingPlaceholder
                    } else {
                        ForEach(viewModel.comments) { comment in
                            commentRow(comment)
                                .task {
                                    if comment.id == viewModel.comments.last?.id {
                                        await viewModel.loadMore()
                                    }
                                }
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.loadComments()
            }

            // Reply indicator
            if let replyingTo = viewModel.replyingTo {
                replyIndicator(replyingTo)
            }

            // Input bar
            commentInputBar
        }
        .navigationTitle(L10n.Comments.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadComments()
        }
    }

    // MARK: - Comment Row

    @ViewBuilder
    private func commentRow(_ comment: Comment) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.sm) {
            AsyncImage(url: comment.author.avatarURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(Color.gray.opacity(DS.Opacity.low))
            }
            .frame(width: DS.Size.avatarMedium, height: DS.Size.avatarMedium)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                // Username + text
                HStack(alignment: .top, spacing: DS.Spacing.xxs) {
                    Text(comment.author.username).fontWeight(.semibold) +
                    Text(" \(comment.text)")
                }
                .font(DS.Font.commentText)

                // Meta row
                HStack(spacing: DS.Spacing.sm) {
                    Text(comment.createdAt, style: .relative)
                    if comment.likesCount > 0 {
                        Text(L10n.Comments.likesCount(comment.likesCount))
                            .fontWeight(.medium)
                    }
                    Button(L10n.Common.reply) {
                        viewModel.handleReply(to: comment)
                        isInputFocused = true
                    }
                    .fontWeight(.medium)
                }
                .font(DS.Font.caption)
                .foregroundStyle(.secondary)

                // Nested replies (one level)
                if !comment.replies.isEmpty {
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        ForEach(comment.replies) { reply in
                            replyRow(reply)
                        }
                    }
                    .padding(.top, DS.Spacing.xs)
                }
            }

            Spacer(minLength: 0)

            // Like button
            VStack {
                Spacer().frame(height: DS.Spacing.xs)
                Button(action: {}) {
                    Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                        .font(DS.Font.caption)
                        .foregroundStyle(comment.isLiked ? ColorTokens.likeRed : .secondary)
                }
            }
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.vertical, DS.Padding.inputBar)
    }

    // MARK: - Reply Row

    @ViewBuilder
    private func replyRow(_ reply: Comment) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.sm) {
            AsyncImage(url: reply.author.avatarURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(Color.gray.opacity(DS.Opacity.low))
            }
            .frame(width: DS.Size.avatarXSmall, height: DS.Size.avatarXSmall)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                HStack(alignment: .top, spacing: DS.Spacing.xxs) {
                    Text(reply.author.username).fontWeight(.semibold) +
                    Text(" \(reply.text)")
                }
                .font(DS.Font.caption)

                HStack(spacing: DS.Spacing.xs) {
                    Text(reply.createdAt, style: .relative)
                    if reply.likesCount > 0 {
                        Text("\(reply.likesCount) likes")
                    }
                }
                .font(DS.Font.caption2)
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Reply Indicator

    @ViewBuilder
    private func replyIndicator(_ comment: Comment) -> some View {
        HStack {
            Text(L10n.Comments.replyingTo)
                .foregroundStyle(.secondary) +
            Text("@\(comment.author.username)")
                .foregroundStyle(ColorTokens.accentPrimary)

            Spacer()

            Button(action: { viewModel.cancelReply() }) {
                Image(systemName: "xmark")
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .font(DS.Font.caption)
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.vertical, DS.Spacing.xs)
        .background(ColorTokens.backgroundSecondary)
    }

    // MARK: - Input Bar

    private var commentInputBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            // Current user avatar placeholder
            Circle()
                .fill(Color.gray.opacity(DS.Opacity.low))
                .frame(width: DS.Size.avatarCompact, height: DS.Size.avatarCompact)

            TextField(
                viewModel.replyingTo != nil ? L10n.Comments.replyPlaceholder : L10n.Comments.addComment,
                text: $commentText
            )
            .textFieldStyle(.plain)
            .font(DS.Font.subheadline)
            .focused($isInputFocused)

            if !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(L10n.Common.post) {
                    let text = commentText
                    commentText = ""
                    Task { await viewModel.addComment(text: text) }
                }
                .font(DS.Font.subheadlineBold)
                .foregroundStyle(ColorTokens.accentPrimary)
                .disabled(viewModel.isSending)
            }
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.vertical, DS.Padding.inputBar)
        .overlay(alignment: .top) { Divider() }
    }

    // MARK: - Loading

    private var loadingPlaceholder: some View {
        VStack(spacing: DS.Spacing.md) {
            ForEach(0..<5, id: \.self) { _ in
                HStack(alignment: .top, spacing: DS.Spacing.sm) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: DS.Size.avatarMedium, height: DS.Size.avatarMedium)
                    VStack(alignment: .leading, spacing: DS.Spacing.iconGap) {
                        RoundedRectangle(cornerRadius: DS.Radius.small)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: DS.Spacing.sm)
                            .frame(maxWidth: .infinity)
                        RoundedRectangle(cornerRadius: DS.Radius.small)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 150, height: DS.Spacing.sm)
                    }
                    Spacer()
                }
                .padding(.horizontal, DS.Padding.horizontal)
            }
        }
        .padding(.top, DS.Spacing.md)
    }
}
