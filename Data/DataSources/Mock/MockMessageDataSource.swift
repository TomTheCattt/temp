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

        // Finite history: only a few pages exist. Beyond that return empty so
        // the ViewModel's `hasMorePages` (result.count < perPage) becomes false.
        guard page <= Self.maxMockPages else { return [] }

        let otherUser = MockData.users.first ?? MockData.currentUser
        let pageCount = min(perPage, Self.messagesPerMockPage)

        // Higher pages are OLDER. Offset each page's timestamps further into the
        // past so merged/sorted results stay strictly ordered without collisions.
        let pageBaseOffset = Double(page - 1) * Double(pageCount) * Self.messageTimeSpacing

        // Newest-first within the page (index 0 = newest of this page).
        return (0..<pageCount).map { index in
            let ageSteps = Double(index) + 1
            return Message(
                // Stable, page-scoped id — distinct per (conversation, page, index).
                id: "msg_\(conversationId)_p\(page)_\(index)",
                conversationId: conversationId,
                sender: index % 3 == 0 ? MockData.currentUser : otherUser,
                content: .text(mockMessages[(page * pageCount + index) % mockMessages.count]),
                status: .read,
                replyToId: nil,
                createdAt: Date(
                    timeIntervalSinceNow: -(pageBaseOffset + ageSteps * Self.messageTimeSpacing)
                )
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

    func createConversation(participantIds: [String]) async throws -> Conversation {
        try await simulateDelay(seconds: 0.4)
        let participants = participantIds.compactMap { id in
            MockData.users.first(where: { $0.id == id })
        }
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

    func deleteMessage(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
    }

    func muteConversation(id: String, mute: Bool) async throws {
        try await simulateDelay(seconds: 0.2)
    }

    // MARK: - Private

    /// Number of distinct older pages of history the mock provides.
    private static let maxMockPages = 3
    /// Messages generated per mock page.
    private static let messagesPerMockPage = 15
    /// Seconds between consecutive mock messages (used to keep timestamps ordered).
    private static let messageTimeSpacing: Double = 300

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
