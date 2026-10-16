//
//  MockMessageDataSource.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Combine
import os

// MARK: - MockMessageDataSource

final class MockMessageDataSource: @unchecked Sendable {

    private let lock = OSAllocatedUnfairLock()
    private var inMemoryConversations: [Conversation] = []
    private var inMemoryMessages: [String: [Message]] = [:]
    private var inMemoryNotes: [InstagramNote] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Initialize conversations from MockData
        self.inMemoryConversations = MockData.conversations

        // Initialize notes
        let currentUserNote = InstagramNote(
            id: "note_current",
            user: MockData.currentUser,
            text: "Đang code Instagram 💻",
            createdAt: .now,
            isCurrentUser: true
        )
        let friendNotes = MockData.users.prefix(6).enumerated().map { index, user in
            let notesPool = [
                "Coffee vibes ☕️",
                "Cháy deadline 🔥",
                "Chill cuối tuần 🎶",
                "On the way ✈️",
                "Gym time 💪",
                "Working remotely 🌴"
            ]
            return InstagramNote(
                id: "note_\(user.id)",
                user: user,
                text: notesPool[index % notesPool.count],
                createdAt: Date(timeIntervalSinceNow: -Double(index * 3600)),
                isCurrentUser: false
            )
        }
        self.inMemoryNotes = [currentUserNote] + friendNotes

        // Initial total unread count calculation
        updateTotalUnreadState()

        // Subscribe to incoming messages (e.g. from WebSocket)
        NotificationCenter.default.publisher(for: .didUpdateMessage)
            .sink { [weak self] notification in
                guard let self = self,
                      let message = notification.object as? Message else { return }
                self.handleExternalMessage(message)
            }
            .store(in: &cancellables)

        // Subscribe to finished calls to record call history into DM
        NotificationCenter.default.publisher(for: .didEndCall)
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let remoteUserId = userInfo["remoteUserId"] as? String else { return }
                let hasVideo = userInfo["hasVideo"] as? Bool ?? false
                let duration = userInfo["duration"] as? String
                let reason = userInfo["reason"] as? String ?? ""
                self.recordCallEndEvent(remoteUserId: remoteUserId, hasVideo: hasVideo, duration: duration, reason: reason)
            }
            .store(in: &cancellables)
    }

    // MARK: - Conversations

    func fetchConversations(page: Int, perPage: Int) async throws -> [Conversation] {
        try await simulateDelay(seconds: 0.05)
        lock.lock()
        defer { lock.unlock() }
        let start = (page - 1) * perPage
        let end = min(start + perPage, inMemoryConversations.count)
        guard start < end else { return [] }
        return Array(inMemoryConversations[start..<end])
    }

    func fetchMessages(conversationId: String, page: Int, perPage: Int) async throws -> [Message] {
        try await simulateDelay(seconds: 0.05)

        lock.lock()
        let newMessages = inMemoryMessages[conversationId] ?? []
        lock.unlock()

        guard page <= Self.maxMockPages else {
            return page == 1 ? newMessages : []
        }

        let otherUser = MockData.users.first ?? MockData.currentUser
        let pageCount = min(perPage, Self.messagesPerMockPage)

        let pageBaseOffset = Double(page - 1) * Double(pageCount) * Self.messageTimeSpacing

        let mockHistory: [Message] = (0..<pageCount).map { index in
            let ageSteps = Double(index) + 1
            return Message(
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

        if page == 1 {
            return newMessages + mockHistory
        } else {
            return mockHistory
        }
    }

    func sendMessage(conversationId: String, content: MessageContent) async throws -> Message {
        try await simulateDelay(seconds: 0.1)

        let message = Message(
            id: "msg_new_\(UUID().uuidString.prefix(8))",
            conversationId: conversationId,
            sender: MockData.currentUser,
            content: content,
            status: .sent,
            replyToId: nil,
            createdAt: .now
        )

        lock.lock()
        // 1. Add to messages cache
        if inMemoryMessages[conversationId] != nil {
            inMemoryMessages[conversationId]?.insert(message, at: 0)
        } else {
            inMemoryMessages[conversationId] = [message]
        }

        // 2. Update conversation lastMessage & move to top (index 0)
        if let index = inMemoryConversations.firstIndex(where: { $0.id == conversationId }) {
            let existing = inMemoryConversations.remove(at: index)
            let updated = Conversation(
                id: existing.id,
                participants: existing.participants,
                lastMessage: message,
                unreadCount: existing.unreadCount,
                isGroup: existing.isGroup,
                groupName: existing.groupName,
                groupAvatarURL: existing.groupAvatarURL,
                updatedAt: message.createdAt,
                isMuted: existing.isMuted
            )
            inMemoryConversations.insert(updated, at: 0)
        }
        lock.unlock()

        // 3. Post notifications to sync UI in DirectMessagesView & MainTabView
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)

        return message
    }

    func markAsRead(conversationId: String) async throws {
        try await simulateDelay(seconds: 0.05)

        lock.lock()
        if let index = inMemoryConversations.firstIndex(where: { $0.id == conversationId }) {
            let existing = inMemoryConversations[index]
            if existing.unreadCount > 0 {
                inMemoryConversations[index] = Conversation(
                    id: existing.id,
                    participants: existing.participants,
                    lastMessage: existing.lastMessage,
                    unreadCount: 0,
                    isGroup: existing.isGroup,
                    groupName: existing.groupName,
                    groupAvatarURL: existing.groupAvatarURL,
                    updatedAt: existing.updatedAt,
                    isMuted: existing.isMuted
                )
            }
        }
        lock.unlock()

        updateTotalUnreadState()
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
    }

    func createConversation(participantIds: [String]) async throws -> Conversation {
        try await simulateDelay(seconds: 0.1)
        let participants = participantIds.compactMap { id in
            MockData.users.first(where: { $0.id == id })
        }
        let newConv = Conversation(
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

        lock.lock()
        inMemoryConversations.insert(newConv, at: 0)
        lock.unlock()

        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
        return newConv
    }

    func deleteMessage(id: String) async throws {
        try await simulateDelay(seconds: 0.05)
        lock.lock()
        for key in inMemoryMessages.keys {
            inMemoryMessages[key]?.removeAll { $0.id == id }
        }
        lock.unlock()
    }

    func muteConversation(id: String, mute: Bool) async throws {
        try await simulateDelay(seconds: 0.05)
        lock.lock()
        if let index = inMemoryConversations.firstIndex(where: { $0.id == id }) {
            let conv = inMemoryConversations[index]
            inMemoryConversations[index] = Conversation(
                id: conv.id,
                participants: conv.participants,
                lastMessage: conv.lastMessage,
                unreadCount: conv.unreadCount,
                isGroup: conv.isGroup,
                groupName: conv.groupName,
                groupAvatarURL: conv.groupAvatarURL,
                updatedAt: conv.updatedAt,
                isMuted: mute
            )
        }
        lock.unlock()
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
    }

    func deleteConversation(id: String) async throws {
        try await simulateDelay(seconds: 0.05)
        lock.lock()
        inMemoryConversations.removeAll { $0.id == id }
        inMemoryMessages.removeValue(forKey: id)
        lock.unlock()

        updateTotalUnreadState()
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
    }

    func addReaction(messageId: String, emoji: String) async throws {
        try await simulateDelay(seconds: 0.05)
    }

    func fetchNotes() async throws -> [InstagramNote] {
        try await simulateDelay(seconds: 0.05)
        lock.lock()
        defer { lock.unlock() }
        return inMemoryNotes
    }

    // MARK: - Real-time Incoming Message Handling

    private func handleExternalMessage(_ message: Message) {
        // Skip messages sent by current user as they are handled in sendMessage
        guard message.sender.id != MockData.currentUser.id else { return }

        lock.lock()
        let convId = message.conversationId
        if inMemoryMessages[convId] != nil {
            if !(inMemoryMessages[convId]?.contains(where: { $0.id == message.id }) ?? false) {
                inMemoryMessages[convId]?.insert(message, at: 0)
            }
        } else {
            inMemoryMessages[convId] = [message]
        }

        if let index = inMemoryConversations.firstIndex(where: { $0.id == convId }) {
            let existing = inMemoryConversations.remove(at: index)
            let updated = Conversation(
                id: existing.id,
                participants: existing.participants,
                lastMessage: message,
                unreadCount: existing.unreadCount + 1,
                isGroup: existing.isGroup,
                groupName: existing.groupName,
                groupAvatarURL: existing.groupAvatarURL,
                updatedAt: message.createdAt,
                isMuted: existing.isMuted
            )
            inMemoryConversations.insert(updated, at: 0)
        } else {
            // New conversation incoming
            let newConv = Conversation(
                id: convId,
                participants: [MockData.currentUser, message.sender],
                lastMessage: message,
                unreadCount: 1,
                isGroup: false,
                groupName: nil,
                groupAvatarURL: nil,
                updatedAt: message.createdAt,
                isMuted: false
            )
            inMemoryConversations.insert(newConv, at: 0)
        }
        lock.unlock()

        updateTotalUnreadState()
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
    }

    private func recordCallEndEvent(remoteUserId: String, hasVideo: Bool, duration: String?, reason: String) {
        lock.lock()
        // Find conversation with this user
        guard let convIndex = inMemoryConversations.firstIndex(where: { conv in
            conv.participants.contains(where: { $0.id == remoteUserId })
        }) else {
            lock.unlock()
            return
        }

        let conv = inMemoryConversations[convIndex]
        let callTypeStr = hasVideo ? "Cuộc gọi video" : "Cuộc gọi thoại"
        let contentText: String

        if let duration = duration, !duration.isEmpty, duration != "00:00" {
            contentText = "\(callTypeStr) đã kết thúc · \(duration)"
        } else if reason == "rejected" || reason == "busy" {
            contentText = "\(callTypeStr) bị từ chối"
        } else if reason == "timeout" {
            contentText = "\(callTypeStr) nhỡ"
        } else {
            contentText = "\(callTypeStr) đã kết thúc"
        }

        let callMessage = Message(
            id: "call_\(UUID().uuidString)",
            conversationId: conv.id,
            sender: MockData.currentUser,
            content: .text(contentText),
            status: .read,
            replyToId: nil,
            createdAt: Date()
        )

        if inMemoryMessages[conv.id] != nil {
            inMemoryMessages[conv.id]?.insert(callMessage, at: 0)
        } else {
            inMemoryMessages[conv.id] = [callMessage]
        }

        let existing = inMemoryConversations.remove(at: convIndex)
        let updated = Conversation(
            id: existing.id,
            participants: existing.participants,
            lastMessage: callMessage,
            unreadCount: existing.unreadCount,
            isGroup: existing.isGroup,
            groupName: existing.groupName,
            groupAvatarURL: existing.groupAvatarURL,
            updatedAt: Date(),
            isMuted: existing.isMuted
        )
        inMemoryConversations.insert(updated, at: 0)
        lock.unlock()

        NotificationCenter.default.post(name: .didUpdateMessage, object: callMessage)
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
    }

    private func updateTotalUnreadState() {
        lock.lock()
        let total = inMemoryConversations.reduce(0) { $0 + $1.unreadCount }
        lock.unlock()

        Task { @MainActor in
            AppState.shared.setUnreadChatCount(total)
        }
    }

    // MARK: - Private Constants

    private static let maxMockPages = 3
    private static let messagesPerMockPage = 15
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
