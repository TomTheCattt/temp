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

    var body: some View {
        List {
            if viewModel.isLoading && viewModel.conversations.isEmpty {
                ForEach(0..<6, id: \.self) { _ in
                    conversationPlaceholder
                }
            } else {
                ForEach(viewModel.conversations) { conversation in
                    ConversationRow(conversation: conversation)
                        .onTapGesture {
                            AppRouter.shared.push(.conversation(conversationId: conversation.id))
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: DS.Spacing.xxs, leading: DS.Spacing.md, bottom: DS.Spacing.xxs, trailing: DS.Spacing.md))
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(MockData.currentUser.username)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // New message
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(DS.Font.title3)
                }
                .tint(.primary)
            }
        }
        .task {
            if viewModel.conversations.isEmpty {
                await viewModel.loadConversations()
            }
        }
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
            let otherUser = conversation.participants.first { $0.id != MockData.currentUser.id }

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
            return Text("No messages yet")
        }

        let isMine = message.sender.id == MockData.currentUser.id
        let prefix = isMine ? "You: " : ""

        switch message.content {
        case .text(let text):
            return Text(prefix + text)
        case .image:
            return Text(prefix + "Sent a photo")
        case .video:
            return Text(prefix + "Sent a video")
        case .audio:
            return Text(prefix + "Sent a voice message")
        case .post:
            return Text(prefix + "Shared a post")
        case .story:
            return Text(prefix + "Shared a story")
        case .reel:
            return Text(prefix + "Shared a reel")
        case .like:
            return Text(prefix + "❤️")
        }
    }
}
