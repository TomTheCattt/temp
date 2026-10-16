//
//  MockMessageDataSource.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import UIKit

// MARK: - MockMessageDataSource

actor MockMessageDataSource {

    private var inMemoryConversations: [Conversation] = []
    private var inMemoryMessages: [String: [Message]] = [:]
    private var inMemoryNotes: [InstagramNote] = []

    init() {
        let conversations = MockData.conversations
        self.inMemoryConversations = conversations

        // Seed inMemoryMessages for all conversations so that conversation.lastMessage
        // is guaranteed to be the newest message (index 0) in the conversation's history.
        var seededMessages: [String: [Message]] = [:]
        for conv in conversations {
            let partner = conv.participants.first { $0.id != MockData.currentUser.id } ?? MockData.users.first ?? MockData.currentUser
            var list: [Message] = []

            if let last = conv.lastMessage {
                list.append(last)
                let baseDate = last.createdAt

                // Generate preceding contextual dialogue in reverse chronological order
                let count = 12
                for i in 1...count {
                    let sender = (i % 2 == 1) ? partner : MockData.currentUser
                    let text = Self.precedingDialogue[(i - 1) % Self.precedingDialogue.count]
                    let msgDate = baseDate.addingTimeInterval(-Double(i) * Self.messageTimeSpacing)
                    list.append(
                        Message(
                            id: "msg_\(conv.id)_hist_\(i)",
                            conversationId: conv.id,
                            sender: sender,
                            content: .text(text),
                            status: .read,
                            replyToId: nil,
                            createdAt: msgDate
                        )
                    )
                }
            }
            seededMessages[conv.id] = list
        }
        self.inMemoryMessages = seededMessages

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
        let initialTotal = conversations.filter { $0.unreadCount != 0 }.count
        Task { @MainActor in
            AppState.shared.setUnreadChatCount(initialTotal)
        }

        // Subscribe to incoming messages (e.g. from WebSocket) via modern AsyncSequence
        Task { [weak self] in
            for await notification in NotificationCenter.default.notifications(named: .didUpdateMessage) {
                guard let self = self,
                      let message = notification.object as? Message else { continue }
                await self.handleExternalMessage(message)
            }
        }

        // Subscribe to finished calls to record call history into DM via modern AsyncSequence
        Task { [weak self] in
            for await notification in NotificationCenter.default.notifications(named: .didEndCall) {
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let remoteUserId = userInfo["remoteUserId"] as? String else { continue }
                let callerUserId = userInfo["callerUserId"] as? String ?? ""
                let isOutgoing = userInfo["isOutgoing"] as? Bool ?? true
                let hasVideo = userInfo["hasVideo"] as? Bool ?? false
                let duration = userInfo["duration"] as? String
                let reason = userInfo["reason"] as? String ?? ""
                await self.recordCallEndEvent(
                    remoteUserId: remoteUserId,
                    callerUserId: callerUserId,
                    isOutgoing: isOutgoing,
                    hasVideo: hasVideo,
                    duration: duration,
                    reason: reason
                )
            }
        }
    }

    // MARK: - Conversations

    func fetchConversations(page: Int, perPage: Int) async throws -> [Conversation] {
        try await simulateDelay(seconds: 0.05)
        let start = (page - 1) * perPage
        let end = min(start + perPage, inMemoryConversations.count)
        guard start < end else { return [] }
        return Array(inMemoryConversations[start..<end])
    }

    func fetchMessages(conversationId: String, page: Int, perPage: Int) async throws -> [Message] {
        try await simulateDelay(seconds: 0.05)

        // Ensure entry exists for conversationId
        if inMemoryMessages[conversationId] == nil {
            if let conv = inMemoryConversations.first(where: { $0.id == conversationId }) {
                inMemoryMessages[conversationId] = conv.lastMessage.map { [$0] } ?? []
            } else {
                inMemoryMessages[conversationId] = []
            }
        }

        var currentMessages = inMemoryMessages[conversationId] ?? []
        let start = (page - 1) * perPage

        // If requested page exceeds cached messages, synthesize older history if within max pages
        if start >= currentMessages.count && page <= Self.maxMockPages {
            let partner: User = {
                if let conv = inMemoryConversations.first(where: { $0.id == conversationId }) {
                    return conv.participants.first { $0.id != MockData.currentUser.id } ?? MockData.currentUser
                }
                return MockData.users.first ?? MockData.currentUser
            }()

            let oldestDate = currentMessages.last?.createdAt ?? Date()
            var olderBatch: [Message] = []
            for i in 1...perPage {
                let sender = (i % 2 == 1) ? partner : MockData.currentUser
                let text = Self.precedingDialogue[(currentMessages.count + i) % Self.precedingDialogue.count]
                let date = oldestDate.addingTimeInterval(-Double(i) * Self.messageTimeSpacing)
                olderBatch.append(
                    Message(
                        id: "msg_\(conversationId)_p\(page)_\(i)",
                        conversationId: conversationId,
                        sender: sender,
                        content: .text(text),
                        status: .read,
                        replyToId: nil,
                        createdAt: date
                    )
                )
            }
            currentMessages.append(contentsOf: olderBatch)
            inMemoryMessages[conversationId] = currentMessages
        }

        guard start < currentMessages.count else { return [] }
        let end = min(start + perPage, currentMessages.count)
        return Array(currentMessages[start..<end])
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

        // 3. Post notifications to sync UI in DirectMessagesView & MainTabView
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)

        return message
    }

    func markAsRead(conversationId: String) async throws {
        try await simulateDelay(seconds: 0.05)

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

        updateTotalUnreadState()
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
    }

    func markAsUnread(conversationId: String) async throws {
        try await simulateDelay(seconds: 0.05)

        if let index = inMemoryConversations.firstIndex(where: { $0.id == conversationId }) {
            let existing = inMemoryConversations[index]
            if existing.unreadCount == 0 {
                inMemoryConversations[index] = Conversation(
                    id: existing.id,
                    participants: existing.participants,
                    lastMessage: existing.lastMessage,
                    unreadCount: 1,
                    isGroup: existing.isGroup,
                    groupName: existing.groupName,
                    groupAvatarURL: existing.groupAvatarURL,
                    updatedAt: existing.updatedAt,
                    isMuted: existing.isMuted
                )
            }
        }

        updateTotalUnreadState()
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
    }

    func getUnreadConversationsCount() -> Int {
        inMemoryConversations.filter { $0.unreadCount > 0 }.count
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

        inMemoryConversations.insert(newConv, at: 0)

        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
        return newConv
    }

    func deleteMessage(id: String) async throws {
        try await simulateDelay(seconds: 0.05)
        for (convId, msgs) in inMemoryMessages {
            if let targetIndex = msgs.firstIndex(where: { $0.id == id }) {
                var updatedMsgs = msgs
                updatedMsgs.remove(at: targetIndex)
                inMemoryMessages[convId] = updatedMsgs

                // Synchronize conversation's lastMessage
                if let convIndex = inMemoryConversations.firstIndex(where: { $0.id == convId }) {
                    let existing = inMemoryConversations[convIndex]
                    let newLastMessage = updatedMsgs.first
                    let newUpdatedAt = newLastMessage?.createdAt ?? existing.updatedAt
                    inMemoryConversations[convIndex] = Conversation(
                        id: existing.id,
                        participants: existing.participants,
                        lastMessage: newLastMessage,
                        unreadCount: existing.unreadCount,
                        isGroup: existing.isGroup,
                        groupName: existing.groupName,
                        groupAvatarURL: existing.groupAvatarURL,
                        updatedAt: newUpdatedAt,
                        isMuted: existing.isMuted
                    )
                }
                NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
                break
            }
        }
    }

    func muteConversation(id: String, mute: Bool) async throws {
        try await simulateDelay(seconds: 0.05)
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
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
    }

    func deleteConversation(id: String) async throws {
        try await simulateDelay(seconds: 0.05)
        inMemoryConversations.removeAll { $0.id == id }
        inMemoryMessages.removeValue(forKey: id)

        updateTotalUnreadState()
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
    }

    func addReaction(messageId: String, emoji: String) async throws {
        try await simulateDelay(seconds: 0.05)
    }

    func fetchNotes() async throws -> [InstagramNote] {
        try await simulateDelay(seconds: 0.05)
        return inMemoryNotes
    }

    // MARK: - Real-time Incoming Message Handling

    private func handleExternalMessage(_ message: Message) {
        // Skip messages sent by current user as they are handled in sendMessage
        guard message.sender.id != MockData.currentUser.id else { return }

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

        updateTotalUnreadState()
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
    }

    private func recordCallEndEvent(
        remoteUserId: String,
        callerUserId: String,
        isOutgoing: Bool,
        hasVideo: Bool,
        duration: String?,
        reason: String
    ) {
        // Find partner user
        let partnerUser: User
        if let user = MockData.users.first(where: { $0.id == remoteUserId }) {
            partnerUser = user
        } else if let found = inMemoryConversations.flatMap(\.participants).first(where: { $0.id == remoteUserId }) {
            partnerUser = found
        } else {
            partnerUser = User(
                id: remoteUserId,
                username: "user_\(remoteUserId)",
                fullName: "User \(remoteUserId)",
                email: nil,
                phone: nil,
                avatarURL: URL(string: "https://i.pravatar.cc/300?u=\(remoteUserId)"),
                bio: nil,
                website: nil,
                isVerified: false,
                isPrivate: false,
                followersCount: 0,
                followingCount: 0,
                postsCount: 0,
                createdAt: .now,
                isFollowing: false,
                isFollowedBy: false,
                isBlocked: false
            )
        }

        let sender: User = isOutgoing ? MockData.currentUser : partnerUser
        let callTypeStr = hasVideo ? "Cuộc gọi video" : "Cuộc gọi thoại"
        let contentText: String

        if let duration = duration, !duration.isEmpty, duration != "00:00" {
            contentText = "\(callTypeStr) đã kết thúc · \(duration)"
        } else if reason == "rejected" || reason == "busy" {
            contentText = "\(callTypeStr) bị từ chối"
        } else if reason == "timeout" {
            if isOutgoing {
                contentText = "\(callTypeStr) không trả lời"
            } else {
                contentText = "\(callTypeStr) nhỡ"
            }
        } else {
            contentText = "\(callTypeStr) đã kết thúc"
        }

        // Determine if conversation already exists
        if let convIndex = inMemoryConversations.firstIndex(where: { conv in
            conv.participants.contains(where: { $0.id == remoteUserId })
        }) {
            let conv = inMemoryConversations[convIndex]
            let isMissedIncoming = !isOutgoing && (reason == "timeout" || duration == nil || duration == "00:00")
            let newUnreadCount = isMissedIncoming ? conv.unreadCount + 1 : conv.unreadCount

            let callMessage = Message(
                id: "call_\(UUID().uuidString)",
                conversationId: conv.id,
                sender: sender,
                content: .text(contentText),
                status: isOutgoing ? .read : (isMissedIncoming ? .delivered : .read),
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
                unreadCount: newUnreadCount,
                isGroup: existing.isGroup,
                groupName: existing.groupName,
                groupAvatarURL: existing.groupAvatarURL,
                updatedAt: Date(),
                isMuted: existing.isMuted
            )
            inMemoryConversations.insert(updated, at: 0)

            NotificationCenter.default.post(name: .didUpdateMessage, object: callMessage)
            NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
            updateTotalUnreadState()
        } else {
            // Auto-create new Conversation for remoteUserId
            let newConvId = "conv_\(remoteUserId)"
            let isMissedIncoming = !isOutgoing && (reason == "timeout" || duration == nil || duration == "00:00")
            let unreadCount = isMissedIncoming ? 1 : 0

            let callMessage = Message(
                id: "call_\(UUID().uuidString)",
                conversationId: newConvId,
                sender: sender,
                content: .text(contentText),
                status: isOutgoing ? .read : (isMissedIncoming ? .delivered : .read),
                replyToId: nil,
                createdAt: Date()
            )

            inMemoryMessages[newConvId] = [callMessage]

            let newConv = Conversation(
                id: newConvId,
                participants: [MockData.currentUser, partnerUser],
                lastMessage: callMessage,
                unreadCount: unreadCount,
                isGroup: false,
                groupName: nil,
                groupAvatarURL: nil,
                updatedAt: Date(),
                isMuted: false
            )
            inMemoryConversations.insert(newConv, at: 0)

            NotificationCenter.default.post(name: .didUpdateMessage, object: callMessage)
            NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
            updateTotalUnreadState()
        }
    }

    private func updateTotalUnreadState() {
        let unreadConversations = inMemoryConversations.filter { $0.unreadCount > 0 }.count

        Task { @MainActor in
            AppState.shared.setUnreadChatCount(unreadConversations)
            #if !targetEnvironment(simulator)
            UNUserNotificationCenter.current().setBadgeCount(unreadConversations)
            #endif
        }
    }

    // MARK: - Private Constants

    private static let maxMockPages = 3
    private static let messagesPerMockPage = 15
    private static let messageTimeSpacing: Double = 180

    private static let precedingDialogue = [
        "Hey! How is everything going? 👋",
        "Pretty good! Just wrapping up some tasks.",
        "Did you get a chance to check out the latest design?",
        "Yes, the UI components and color palette look amazing! 🎨",
        "Awesome! Let me know if you need any adjustments.",
        "Will do. Are we still meeting for lunch later? 🍜",
        "Definitely, let's meet around 12:30 at the lobby.",
        "Sounds like a plan! See you soon. 👍",
        "By the way, did you see the new feature demo?",
        "Not yet, send me the link when you can!",
        "Sent! Let me know your thoughts after reviewing.",
        "Got it, looking at it right now. Looks super clean! ✨"
    ]

    private func simulateDelay(seconds: Double = 0.5) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
