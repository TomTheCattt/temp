//
//  Message.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - Conversation

nonisolated struct Conversation: Identifiable, Hashable, Sendable {
    let id: String
    let participants: [User]
    let lastMessage: Message?
    let unreadCount: Int
    let isGroup: Bool
    let groupName: String?
    let groupAvatarURL: URL?
    let updatedAt: Date
    let isMuted: Bool
}

// MARK: - Message

nonisolated struct Message: Identifiable, Hashable, Sendable {
    let id: String
    let conversationId: String
    let sender: User
    let content: MessageContent
    let status: MessageStatus
    let replyToId: String?
    let replyToSnippet: String?
    let reactions: [String: String] // [userId: emoji] e.g. ["user_1": "❤️"]
    let createdAt: Date

    init(
        id: String,
        conversationId: String,
        sender: User,
        content: MessageContent,
        status: MessageStatus,
        replyToId: String? = nil,
        replyToSnippet: String? = nil,
        reactions: [String: String] = [:],
        createdAt: Date
    ) {
        self.id = id
        self.conversationId = conversationId
        self.sender = sender
        self.content = content
        self.status = status
        self.replyToId = replyToId
        self.replyToSnippet = replyToSnippet
        self.reactions = reactions
        self.createdAt = createdAt
    }
}

// MARK: - MessageContent

nonisolated enum MessageContent: Hashable, Sendable {
    case text(String)
    case image(URL)
    case video(URL, thumbnailURL: URL?)
    case audio(URL, duration: TimeInterval)
    case post(postId: String)      // shared post
    case story(storyId: String)    // shared story
    case reel(reelId: String)      // shared reel
    case like                      // "liked a message" reaction
}

// MARK: - MessageStatus

nonisolated enum MessageStatus: String, Sendable, Hashable {
    case sending
    case sent
    case delivered
    case read
    case failed
}

// MARK: - InstagramNote

nonisolated struct InstagramNote: Identifiable, Hashable, Sendable {
    let id: String
    let user: User
    let text: String
    let createdAt: Date
    let isCurrentUser: Bool
}

