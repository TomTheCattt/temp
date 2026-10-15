//
//  DirectMessagesView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import NukeUI

// MARK: - DirectMessagesView

struct DirectMessagesView: View {

    @State private var viewModel = DirectMessagesViewModel(
        messageRepository: DIContainer.shared.resolve(MessageRepositoryProtocol.self)
    )

    @State private var isScrolled: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar for Chat (2 buttons: 1 center, 1 trailing)
            chatNavigationBar

            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.isLoading && viewModel.conversations.isEmpty {
                        ForEach(0..<6, id: \.self) { _ in
                            conversationPlaceholder
                                .padding(.horizontal, DS.Padding.horizontal)
                        }
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.conversations) { conversation in
                                ConversationRow(conversation: conversation)
                                    .onTapGesture {
                                        AppRouter.shared.push(.conversation(conversationId: conversation.id))
                                    }
                                    .padding(.horizontal, DS.Padding.horizontal)
                            }
                        }
                    }
                }
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { _, newOffset in
                let atTop = newOffset <= Constants.scrollThresholdTop
                if atTop != !isScrolled {
                    withAnimation(DS.Animation.standard) {
                        isScrolled = !atTop
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if viewModel.conversations.isEmpty {
                await viewModel.loadConversations()
            }
        }
    }

    // MARK: - Chat Navigation Bar (2 buttons: 1 center, 1 trailing)

    private var chatNavigationBar: some View {
        CustomNavBarView(
            showDivider: true,
            isScrolled: isScrolled,
            leading: {
                Spacer().frame(width: DS.Size.buttonDefaultHeight)
            },
            center: {
                // Button 1: Center (Username dropdown)
                Button {
                    // Account switcher
                } label: {
                    HStack(spacing: DS.Spacing.xxs) {
                        Text(SessionStore.shared.currentUser?.username ?? L10n.Tab.chat)
                            .font(DS.Font.title3)
                            .fontWeight(.bold)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(Color.primary)
                }
            },
            trailing: {
                // Button 2: Trailing (New message / Edit)
                Button {
                    HapticFeedbackSafe.impact(.light)
                    // New message
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(Color.primary)
                        .frame(width: 44, height: 44, alignment: .trailing)
                        .contentShape(Rectangle())
                }
            }
        )
    }

    private var conversationPlaceholder: some View {
        HStack(spacing: DS.Spacing.sm) {
            Circle()
                .fill(ColorTokens.buttonSecondary)
                .frame(width: DS.Size.avatarStoryCircle, height: DS.Size.avatarStoryCircle)
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                RoundedRectangle(cornerRadius: DS.Radius.small)
                    .fill(ColorTokens.buttonSecondary)
                    .frame(width: 120, height: DS.Spacing.formGap)
                RoundedRectangle(cornerRadius: DS.Radius.small)
                    .fill(ColorTokens.backgroundSecondary)
                    .frame(width: 180, height: DS.Spacing.sm)
            }
            Spacer()
        }
        .listRowSeparator(.hidden)
    }
}

// MARK: - ConversationRow

private struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            // Avatar
            let otherUser = conversation.participants.first { $0.id != SessionStore.shared.currentUserId }

            LazyImage(url: otherUser?.avatarURL) { state in
                if let image = state.image {
                    image.resizable()
                } else {
                    Circle().fill(ColorTokens.buttonSecondary)
                }
            }
            .frame(width: DS.Size.avatarStoryCircle, height: DS.Size.avatarStoryCircle)
            .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: DS.Spacing.xxs) {
                    Text(otherUser?.username ?? "Unknown")
                        .font(DS.Font.subheadline)
                        .fontWeight(conversation.unreadCount > 0 ? .bold : .regular)

                    if otherUser?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(DS.Font.caption2)
                            .foregroundStyle(ColorTokens.accentPrimary)
                    }
                }

                HStack(spacing: DS.Spacing.xxs) {
                    lastMessageText
                        .font(DS.Font.subheadline)
                        .foregroundStyle(conversation.unreadCount > 0 ? .primary : .secondary)
                        .lineLimit(1)

                    Text("· \(conversation.updatedAt.timeAgoDisplay())")
                        .font(DS.Font.subheadline)
                        .foregroundStyle(.secondary)

                    // Show delivery/read status for own last message
                    if let statusText = lastMessageStatusText {
                        Text("· \(statusText)")
                            .font(DS.Font.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Unread badge
            if conversation.unreadCount > 0 {
                Circle()
                    .fill(ColorTokens.accentPrimary)
                    .frame(width: DS.Size.iconXSmall, height: DS.Size.iconXSmall)
            }

            // Muted indicator
            if conversation.isMuted {
                Image(systemName: "bell.slash.fill")
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, DS.Spacing.xxs)
        .contentShape(Rectangle())
    }

    private var lastMessageText: Text {
        guard let message = conversation.lastMessage else {
            return Text(L10n.DirectMessages.noMessages)
        }

        let isMine = message.sender.id == SessionStore.shared.currentUserId
        let prefix = isMine ? L10n.DirectMessages.you : ""

        switch message.content {
        case .text(let text):
            return Text(prefix + text)
        case .image:
            return Text(prefix + L10n.DirectMessages.sentPhoto)
        case .video:
            return Text(prefix + L10n.DirectMessages.sentVideo)
        case .audio:
            return Text(prefix + L10n.DirectMessages.sentVoice)
        case .post:
            return Text(prefix + L10n.DirectMessages.sharedPost)
        case .story:
            return Text(prefix + L10n.DirectMessages.sharedStory)
        case .reel:
            return Text(prefix + L10n.DirectMessages.sharedReel)
        case .like:
            return Text(prefix + "❤️")
        }
    }

    /// Returns status text for the last message only if it was sent by the current user.
    /// Shows "Đã gửi" for sent/delivered, "Đã xem" for read, nil otherwise.
    private var lastMessageStatusText: String? {
        guard let message = conversation.lastMessage else { return nil }
        let isMine = message.sender.id == SessionStore.shared.currentUserId
        guard isMine else { return nil }

        switch message.status {
        case .sent, .delivered:
            return L10n.Chat.statusSent
        case .read:
            return L10n.Chat.statusRead
        case .sending, .failed:
            return nil
        }
    }
}

// MARK: - ChatScrollOffsetPreferenceKey

private struct ChatScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Constants

private enum Constants {
    static let scrollThresholdTop: CGFloat = 10
}
