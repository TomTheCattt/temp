//
//  StoryRepliesView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import NukeUI

// MARK: - StoryRepliesView

struct StoryRepliesView: View {

    let storyId: String

    @State private var viewModel: StoryRepliesViewModel
    @Environment(\.dismiss) private var dismiss

    init(storyId: String) {
        self.storyId = storyId
        _viewModel = State(initialValue: StoryRepliesViewModel(
            storyId: storyId,
            storyRepliesUseCase: DIContainer.shared.resolve(StoryRepliesUseCaseProtocol.self)
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                if viewModel.isLoading && viewModel.replies.isEmpty {
                    loadingView
                } else if viewModel.replies.isEmpty {
                    emptyStateView
                } else {
                    repliesList
                }

                // Reply Input Bar at bottom
                VStack {
                    Spacer()
                    replyInputBar
                        .padding(.horizontal, DS.Padding.horizontal)
                        .padding(.bottom, DS.Spacing.md)
                        .background(Color(.systemBackground))
                }
            }
            .navigationTitle(L10n.StoryReplies.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        HapticFeedbackSafe.impact(.light)
                        dismiss()
                    } label: {
                        InstagramIcon(.chevronLeft, size: 20, color: Color.primary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isStoryOwner {
                        Menu {
                            Button {
                                Task {
                                    await viewModel.deleteAllReplies()
                                }
                            } label: {
                                Label(L10n.StoryReplies.deleteAll, systemImage: "trash")
                            }

                            Button {
                                Task {
                                    await viewModel.toggleRepliesEnabled()
                                }
                            } label: {
                                Label(
                                    viewModel.areRepliesEnabled ? L10n.StoryReplies.turnOffReplies : L10n.StoryReplies.turnOnReplies,
                                    systemImage: viewModel.areRepliesEnabled ? "bell.slash" : "bell"
                                )
                            }
                        } label: {
                            InstagramIcon(.system(name: "ellipsis"), size: 20, color: Color.primary)
                                .frame(width: 44, height: 44)
                        }
                    }
                }
            }
            .task {
                await viewModel.loadReplies()
            }
            .refreshable {
                await viewModel.loadReplies()
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: DS.Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            Text(L10n.Common.loading)
                .font(DS.Font.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: DS.Spacing.md) {
            InstagramIcon(.system(name: "bubble.left.and.bubble.right"), size: 64, color: .secondary)
            Text(L10n.StoryReplies.emptyTitle)
                .font(DS.Font.headline)
                .foregroundStyle(.primary)
            Text(L10n.StoryReplies.emptyMessage)
                .font(DS.Font.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Padding.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var repliesList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.replies) { reply in
                    ReplyRow(reply: reply)
                        .onTapGesture {
                            // Navigate to user profile
                            HapticFeedbackSafe.impact(.light)
                            AppRouter.shared.push(.userProfile(userId: reply.user.id))
                        }
                        .contextMenu {
                            if viewModel.isStoryOwner {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteReply(id: reply.id)
                                    }
                                } label: {
                                    Label(L10n.Common.delete, systemImage: "trash")
                                }
                            }
                        }
                }
            }
            .padding(.bottom, 100) // Space for input bar
        }
    }

    private var replyInputBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            // Current user avatar
            LazyImage(url: SessionStore.shared.currentUser?.avatarURL) { state in
                if let image = state.image {
                    image.resizable().scaledToFill()
                } else {
                    Circle().fill(ColorTokens.buttonSecondary)
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())

            // Text field
            HStack(spacing: DS.Spacing.xs) {
                TextField(L10n.StoryReplies.replyPlaceholder, text: $viewModel.replyText, axis: .vertical)
                    .font(DS.Font.body)
                    .lineLimit(1...4)
                    .textFieldStyle(.plain)

                // Send button
                Button {
                    Task {
                        await viewModel.sendReply()
                    }
                } label: {
                    InstagramIcon(.system(name: "paperplane.fill"), size: 20, color: viewModel.canSend ? ColorTokens.accentPrimary : .secondary)
                }
                .disabled(!viewModel.canSend)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.xs)
            .background(ColorTokens.backgroundSecondary, in: Capsule())

            // Camera button
            Button {
                HapticFeedbackSafe.impact(.light)
                AppRouter.shared.present(fullScreen: .creationHub(initialMode: .story))
            } label: {
                InstagramIcon(.camera, size: 20, color: .primary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, DS.Spacing.sm)
        .padding(.vertical, DS.Spacing.xs)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .top)
    }
}

// MARK: - Reply Row

private struct ReplyRow: View {
    let reply: StoryReply

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.sm) {
            // Avatar
            LazyImage(url: reply.user.avatarURL) { state in
                if let image = state.image {
                    image.resizable().scaledToFill()
                } else {
                    Circle().fill(ColorTokens.buttonSecondary)
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                HStack(spacing: DS.Spacing.xxs) {
                    Text(reply.user.username)
                        .font(DS.Font.subheadlineBold)
                        .foregroundStyle(.primary)

                    if reply.user.isVerified {
                        InstagramIcon(.verifiedBadge, size: DS.Size.iconXSmall, color: ColorTokens.accentPrimary)
                    }

                    Text("·")
                        .foregroundStyle(.secondary)

                    Text(reply.createdAt.timeAgoDisplay())
                        .font(DS.Font.caption)
                        .foregroundStyle(.secondary)
                }

                Text(reply.text)
                    .font(DS.Font.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                // Reactions
                if !reply.reactions.isEmpty {
                    HStack(spacing: DS.Spacing.xxs) {
                        ForEach(reply.reactions.prefix(5)) { reaction in
                            Text(reaction.emoji)
                                .font(.system(size: 12))
                        }
                        if reply.reactions.count > 5 {
                            Text("+\(reply.reactions.count - 5)")
                                .font(DS.Font.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, DS.Spacing.xxxs)
                }
            }

            Spacer()
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.vertical, DS.Spacing.sm)
        .background(Color(.systemBackground))
        .overlay(Divider().padding(.leading, 52), alignment: .bottom)
    }
}

