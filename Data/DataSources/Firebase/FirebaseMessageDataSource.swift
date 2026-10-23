//
//  FirebaseMessageDataSource.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation

// MARK: - FirebaseMessageDataSource

/// Skeletal actor for Firebase Direct Messages and real-time conversation synchronization.
/// Ready for rewriting logic from scratch.
actor FirebaseMessageDataSource {

    static let shared = FirebaseMessageDataSource()

    init() {}

    // MARK: - Public Interface

    func fetchConversations(page: Int, perPage: Int) async throws -> [Conversation] {
        _ = page
        _ = perPage
        // TODO: Implement fetchConversations from scratch
        return []
    }

    func fetchMessages(conversationId: String, page: Int, perPage: Int) async throws -> [Message] {
        _ = conversationId
        _ = page
        _ = perPage
        // TODO: Implement fetchMessages from scratch
        return []
    }

    func sendMessage(conversationId: String, content: MessageContent) async throws -> Message {
        _ = conversationId
        // TODO: Implement sendMessage from scratch
        let myId = await SessionStore.shared.currentUserId
        let dummyUser = User(
            id: myId.isEmpty ? "user_me" : myId,
            username: "me",
            fullName: "Me",
            email: nil,
            phone: nil,
            avatarURL: nil,
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
        return Message(
            id: UUID().uuidString,
            conversationId: conversationId,
            sender: dummyUser,
            content: content,
            status: .sent,
            replyToId: nil,
            replyToSnippet: nil,
            reactions: [:],
            createdAt: Date()
        )
    }

    func createConversation(participantIds: [String]) async throws -> Conversation {
        _ = participantIds
        // TODO: Implement createConversation from scratch
        return Conversation(
            id: UUID().uuidString,
            participants: [],
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
        _ = conversationId
        // TODO: Implement markAsRead from scratch
    }

    func markAsUnread(conversationId: String) async throws {
        _ = conversationId
        // TODO: Implement markAsUnread from scratch
    }

    func getUnreadConversationsCount() -> Int {
        return 0
    }

    func deleteMessage(id: String) async throws {
        _ = id
        // TODO: Implement deleteMessage from scratch
    }

    func muteConversation(id: String, mute: Bool) async throws {
        _ = id
        _ = mute
        // TODO: Implement muteConversation from scratch
    }

    func deleteConversation(id: String) async throws {
        _ = id
        // TODO: Implement deleteConversation from scratch
    }

    func addReaction(messageId: String, emoji: String) async throws {
        _ = messageId
        _ = emoji
        // TODO: Implement addReaction from scratch
    }

    func fetchNotes() async throws -> [InstagramNote] {
        // TODO: Implement fetchNotes from scratch
        return []
    }

    func saveNote(text: String) async throws -> InstagramNote {
        // TODO: Implement saveNote from scratch
        let myId = await SessionStore.shared.currentUserId
        let dummyUser = User(
            id: myId.isEmpty ? "user_me" : myId,
            username: "me",
            fullName: "Me",
            email: nil,
            phone: nil,
            avatarURL: nil,
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
        return InstagramNote(
            id: UUID().uuidString,
            user: dummyUser,
            text: text,
            createdAt: .now,
            isCurrentUser: true
        )
    }

    func detachMessageListener(for conversationId: String) {
        _ = conversationId
    }

    func resetSession() {
    }

    func restartSession() async {
    }
}
