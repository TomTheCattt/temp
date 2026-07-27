//
//  MessageRepository.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - MessageRepository

final class MessageRepository: MessageRepositoryProtocol, @unchecked Sendable {

    private let mockDataSource: MockMessageDataSource

    init(mockDataSource: MockMessageDataSource = MockMessageDataSource()) {
        self.mockDataSource = mockDataSource
    }

    func fetchConversations(page: Int, perPage: Int) async throws -> [Conversation] {
        try await mockDataSource.fetchConversations(page: page, perPage: perPage)
    }

    func fetchMessages(conversationId: String, page: Int, perPage: Int) async throws -> [Message] {
        try await mockDataSource.fetchMessages(conversationId: conversationId, page: page, perPage: perPage)
    }

    func sendMessage(conversationId: String, content: MessageContent) async throws -> Message {
        try await mockDataSource.sendMessage(conversationId: conversationId, content: content)
    }

    func createConversation(participantIds: [String]) async throws -> Conversation {
        try await Task.sleep(nanoseconds: 500_000_000)
        let participants = MockData.users.filter { participantIds.contains($0.id) }
        return Conversation(
            id: "conv_new_\(UUID().uuidString.prefix(8))",
            participants: [MockData.currentUser] + participants,
            lastMessage: nil,
            unreadCount: 0,
            isGroup: participantIds.count > 1,
            groupName: nil,
            groupAvatarURL: nil,
            updatedAt: .now,
            isMuted: false
        )
    }

    func markAsRead(conversationId: String) async throws {
        try await mockDataSource.markAsRead(conversationId: conversationId)
    }

    func deleteMessage(id: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }

    func muteConversation(id: String, mute: Bool) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }
}
