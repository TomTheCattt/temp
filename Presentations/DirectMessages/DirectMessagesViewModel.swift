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

    var conversations: [Conversation] = []
    var notes: [InstagramNote] = []
    var isLoading = false
    var searchQuery = ""

    // MARK: - Filtered Conversations

    var filteredConversations: [Conversation] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return conversations }

        let lower = trimmed.lowercased()
        let currentUserId = SessionStore.shared.currentUserId
        return conversations.filter { conv in
            let otherUser = conv.participants.first { $0.id != currentUserId }
                ?? conv.participants.first
            let usernameMatch = otherUser?.username.lowercased().contains(lower) ?? false
            let fullNameMatch = otherUser?.fullName.lowercased().contains(lower) ?? false
            let groupMatch = conv.groupName?.lowercased().contains(lower) ?? false
            return usernameMatch || fullNameMatch || groupMatch
        }
    }

    // MARK: - Dependencies

    private let messageRepository: MessageRepositoryProtocol

    // MARK: - Init

    init(messageRepository: MessageRepositoryProtocol) {
        self.messageRepository = messageRepository
    }

    // MARK: - Sync & Refresh

    func refreshFromLocal() {
        // TODO: Implement refreshFromLocal logic from scratch
    }

    // MARK: - Actions

    func loadConversations() async {
        // TODO: Implement loadConversations logic from scratch
    }

    func markAsRead(conversationId: String) async {
        _ = conversationId
        // TODO: Implement markAsRead logic from scratch
    }

    func deleteConversation(id: String) {
        _ = id
        // TODO: Implement deleteConversation logic from scratch
    }

    func toggleMute(id: String) {
        _ = id
        // TODO: Implement toggleMute logic from scratch
    }

    func toggleUnread(id: String) {
        _ = id
        // TODO: Implement toggleUnread logic from scratch
    }

    func addOrUpdateNote(text: String) {
        _ = text
        // TODO: Implement addOrUpdateNote logic from scratch
    }
}
