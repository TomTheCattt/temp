//
//  DirectMessagesViewModel.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - DirectMessagesViewModel

@MainActor
@Observable
final class DirectMessagesViewModel {

    // MARK: - State

    private(set) var conversations: [Conversation] = []
    private(set) var isLoading = false

    // MARK: - Dependencies

    private let messageRepository: MessageRepositoryProtocol

    // MARK: - Init

    init(messageRepository: MessageRepositoryProtocol) {
        self.messageRepository = messageRepository
    }

    // MARK: - Actions

    func loadConversations() async {
        guard !isLoading else { return }
        isLoading = true

        do {
            conversations = try await messageRepository.fetchConversations(page: 1, perPage: 30)
        } catch {
            // Silent fail
        }

        isLoading = false
    }

    func markAsRead(conversationId: String) async {
        do {
            try await messageRepository.markAsRead(conversationId: conversationId)
            if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                let conv = conversations[index]
                conversations[index] = Conversation(
                    id: conv.id,
                    participants: conv.participants,
                    lastMessage: conv.lastMessage,
                    unreadCount: 0,
                    isGroup: conv.isGroup,
                    groupName: conv.groupName,
                    groupAvatarURL: conv.groupAvatarURL,
                    updatedAt: conv.updatedAt,
                    isMuted: conv.isMuted
                )
            }
        } catch {
            // Silent fail
        }
    }
}
