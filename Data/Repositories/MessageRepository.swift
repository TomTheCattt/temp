//
//  MessageRepository.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - MessageRepository

final class MessageRepository: MessageRepositoryProtocol, @unchecked Sendable {

    private let remoteDataSource: RemoteMessageDataSource
    private let mockDataSource: MockMessageDataSource

    init(
        remoteDataSource: RemoteMessageDataSource,
        mockDataSource: MockMessageDataSource = MockMessageDataSource()
    ) {
        self.remoteDataSource = remoteDataSource
        self.mockDataSource = mockDataSource
    }

    func fetchConversations(page: Int, perPage: Int) async throws -> [Conversation] {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchConversations(page: page, perPage: perPage)
        }
        return try await remoteDataSource.fetchConversations(page: page, perPage: perPage)
    }

    func fetchMessages(conversationId: String, page: Int, perPage: Int) async throws -> [Message] {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchMessages(conversationId: conversationId, page: page, perPage: perPage)
        }
        return try await remoteDataSource.fetchMessages(conversationId: conversationId, page: page, perPage: perPage)
    }

    func sendMessage(conversationId: String, content: MessageContent) async throws -> Message {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.sendMessage(conversationId: conversationId, content: content)
        }
        return try await remoteDataSource.sendMessage(conversationId: conversationId, content: content)
    }

    func createConversation(participantIds: [String]) async throws -> Conversation {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.createConversation(participantIds: participantIds)
        }
        return try await remoteDataSource.createConversation(participantIds: participantIds)
    }

    func markAsRead(conversationId: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.markAsRead(conversationId: conversationId)
        }
        try await remoteDataSource.markAsRead(conversationId: conversationId)
    }

    func deleteMessage(id: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.deleteMessage(id: id)
        }
        try await remoteDataSource.deleteMessage(id: id)
    }

    func muteConversation(id: String, mute: Bool) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.muteConversation(id: id, mute: mute)
        }
        try await remoteDataSource.muteConversation(id: id, mute: mute)
    }
}
