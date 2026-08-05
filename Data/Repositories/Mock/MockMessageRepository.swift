//
//  MockMessageRepository.swift
//  Instagram
//
//  Created by Kiro on 5/8/26.
//

import Foundation

// MARK: - MockMessageRepository

/// Mock implementation of MessageRepositoryProtocol for UI testing with local data.
final class MockMessageRepository: MessageRepositoryProtocol, @unchecked Sendable {

    private let dataSource = MockMessageDataSource()

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

    func deleteMessage(id: String) async throws {
        try await dataSource.deleteMessage(id: id)
    }

    func muteConversation(id: String, mute: Bool) async throws {
        try await dataSource.muteConversation(id: id, mute: mute)
    }
}
