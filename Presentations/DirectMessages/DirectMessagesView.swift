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
        messageRepository: MessageRepository()
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
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
                        .font(.title3)
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
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 180, height: 12)
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
        HStack(spacing: 12) {
            // Avatar
            let otherUser = conversation.participants.first { $0.id != MockData.currentUser.id }

            LazyImage(url: otherUser?.avatarURL) { state in
                if let image = state.image {
                    image.resizable()
                } else {
                    Circle().fill(Color(.systemGray5))
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(otherUser?.username ?? "Unknown")
                        .font(.subheadline)
                        .fontWeight(conversation.unreadCount > 0 ? .bold : .regular)

                    if otherUser?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }

                HStack(spacing: 4) {
                    lastMessageText
                        .font(.subheadline)
                        .foregroundStyle(conversation.unreadCount > 0 ? .primary : .secondary)
                        .lineLimit(1)

                    Text("· \(conversation.updatedAt.timeAgoDisplay())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Unread badge
            if conversation.unreadCount > 0 {
                Circle()
                    .fill(.blue)
                    .frame(width: 8, height: 8)
            }

            // Muted indicator
            if conversation.isMuted {
                Image(systemName: "bell.slash.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
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
