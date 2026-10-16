//
//  MessageRepositoryProtocol.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - MessageRepositoryProtocol

protocol MessageRepositoryProtocol: Sendable {

    /// Fetch list of conversations.
    func fetchConversations(page: Int, perPage: Int) async throws -> [Conversation]

    /// Fetch messages in a conversation.
    func fetchMessages(conversationId: String, page: Int, perPage: Int) async throws -> [Message]

    /// Send a message.
    func sendMessage(conversationId: String, content: MessageContent) async throws -> Message

    /// Create a new conversation (DM).
    func createConversation(participantIds: [String]) async throws -> Conversation

    /// Mark messages as read.
    func markAsRead(conversationId: String) async throws

    /// Mark a conversation as unread.
    func markAsUnread(conversationId: String) async throws

    /// Get total number of unread conversations.
    func getUnreadConversationsCount() async throws -> Int

    /// Delete a message.
    func deleteMessage(id: String) async throws

    /// Mute/unmute a conversation.
    func muteConversation(id: String, mute: Bool) async throws

    /// Delete a conversation.
    func deleteConversation(id: String) async throws

    /// Add or remove emoji reaction to a message.
    func addReaction(messageId: String, emoji: String) async throws

    /// Fetch active notes for the current user and following friends.
    func fetchNotes() async throws -> [InstagramNote]
}

// MARK: - MessageRepositoryProtocol Extension Defaults

extension MessageRepositoryProtocol {

    func deleteConversation(id: String) async throws {}

    func addReaction(messageId: String, emoji: String) async throws {}

    func fetchNotes() async throws -> [InstagramNote] {
        return []
    }

    func getUnreadConversationsCount() async throws -> Int {
        return 0
    }

    func markAsUnread(conversationId: String) async throws {}
}

