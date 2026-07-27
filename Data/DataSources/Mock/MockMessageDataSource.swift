//
//  MockMessageDataSource.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - MockMessageDataSource

final class MockMessageDataSource: Sendable {

    func fetchConversations(page: Int, perPage: Int) async throws -> [Conversation] {
        try await simulateDelay()
        return MockData.conversations
    }

    func fetchMessages(conversationId: String, page: Int, perPage: Int) async throws -> [Message] {
        try await simulateDelay()

        // Generate some mock messages for the conversation
        let otherUser = MockData.users.first ?? MockData.currentUser
        return (0..<15).map { index in
            Message(
                id: "msg_\(conversationId)_\(index)",
                conversationId: conversationId,
                sender: index % 3 == 0 ? MockData.currentUser : otherUser,
                content: .text(mockMessages[index % mockMessages.count]),
                status: .read,
                replyToId: nil,
                createdAt: Date(timeIntervalSinceNow: -Double(15 - index) * 300)
            )
        }
    }

    func sendMessage(conversationId: String, content: MessageContent) async throws -> Message {
        try await simulateDelay(seconds: 0.3)
        return Message(
            id: "msg_new_\(UUID().uuidString.prefix(8))",
            conversationId: conversationId,
            sender: MockData.currentUser,
            content: content,
            status: .sent,
            replyToId: nil,
            createdAt: .now
        )
    }

    func markAsRead(conversationId: String) async throws {
        try await simulateDelay(seconds: 0.1)
    }

    // MARK: - Private

    private let mockMessages = [
        "Hey! What's up? 👋",
        "Not much, just working on a new project",
        "That sounds cool! What kind of project?",
        "An Instagram clone 😄",
        "No way! That's awesome",
        "Yeah, it's been fun building it",
        "Let me know if you need help!",
        "Thanks! Will do 🙏",
        "How's the weather there?",
        "Pretty nice today, sunny ☀️",
        "Same here! Perfect day",
        "Want to grab coffee later?",
        "Sure! Around 3pm?",
        "Sounds good, see you then!",
        "Great, see you! 👋",
    ]

    private func simulateDelay(seconds: Double = 0.5) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
