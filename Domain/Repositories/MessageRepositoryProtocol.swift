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

    /// Delete a message.
    func deleteMessage(id: String) async throws

    /// Mute/unmute a conversation.
    func muteConversation(id: String, mute: Bool) async throws
}
