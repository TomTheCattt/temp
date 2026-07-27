//
//  Message.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - Conversation

struct Conversation: Identifiable, Hashable, Sendable {
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

struct Message: Identifiable, Hashable, Sendable {
    let id: String
    let conversationId: String
    let sender: User
    let content: MessageContent
    let status: MessageStatus
    let replyToId: String?
    let createdAt: Date
}

// MARK: - MessageContent

enum MessageContent: Hashable, Sendable {
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

enum MessageStatus: String, Sendable, Hashable {
    case sending
    case sent
    case delivered
    case read
    case failed
}
