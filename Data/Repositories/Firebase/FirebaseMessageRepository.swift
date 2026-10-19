//
//  FirebaseMessageRepository.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation

// MARK: - FirebaseMessageRepository

/// Production implementation of MessageRepositoryProtocol backed by FirebaseMessageDataSource.
final class FirebaseMessageRepository: MessageRepositoryProtocol, @unchecked Sendable {

    private let dataSource: FirebaseMessageDataSource

    init(dataSource: FirebaseMessageDataSource = FirebaseMessageDataSource.shared) {
        self.dataSource = dataSource
    }

    func fetchConversations(page: Int, perPage: Int) async throws -> [Conversation] {
        try await dataSource.fetchConversations(page: page, perPage: perPage)
    }

    func fetchMessages(conversationId: String, page: Int, perPage: Int) async throws -> [Message] {
        try await dataSource.fetchMessages(conversationId: conversationId, page: page, perPage: perPage)
    }

    func sendMessage(conversationId: String, content: MessageContent) async throws -> Message {
        try await dataSource.sendMessage(conversationId: conversationId, content: content)
    }

    func createConversation(participantIds: [String]) async throws -> Conversation {
        try await dataSource.createConversation(participantIds: participantIds)
    }

    func markAsRead(conversationId: String) async throws {
        try await dataSource.markAsRead(conversationId: conversationId)
    }

    func markAsUnread(conversationId: String) async throws {
        try await dataSource.markAsUnread(conversationId: conversationId)
    }

    func getUnreadConversationsCount() async throws -> Int {
        await dataSource.getUnreadConversationsCount()
    }

    func deleteMessage(id: String) async throws {
        try await dataSource.deleteMessage(id: id)
    }

    func muteConversation(id: String, mute: Bool) async throws {
        try await dataSource.muteConversation(id: id, mute: mute)
    }

    func deleteConversation(id: String) async throws {
        try await dataSource.deleteConversation(id: id)
    }

    func addReaction(messageId: String, emoji: String) async throws {
        try await dataSource.addReaction(messageId: messageId, emoji: emoji)
    }

    func fetchNotes() async throws -> [InstagramNote] {
        try await dataSource.fetchNotes()
    }
}
