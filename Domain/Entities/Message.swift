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

    /// The definitive timestamp for chronological inbox sorting and display.
    /// Combines conversation update timestamp with the most recent message createdAt.
    var effectiveDate: Date {
        if let msgDate = lastMessage?.createdAt {
            return max(updatedAt, msgDate)
        }
        return updatedAt
    }
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

nonisolated enum MessageContent: Hashable, Sendable, Codable {
    case text(String)
    case image(URL)
    case video(URL, thumbnailURL: URL?)
    case audio(URL, duration: TimeInterval)
    case post(postId: String)      // shared post
    case story(storyId: String)    // shared story
    case reel(reelId: String)      // shared reel
    case like                      // "liked a message" reaction

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case imageURL
        case videoURL
        case thumbnailURL
        case audioURL
        case duration
        case postId
        case storyId
        case reelId
    }

    private enum ContentType: String, Codable {
        case text, image, video, audio, post, story, reel, like
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)

        switch type {
        case .text:
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        case .image:
            let url = try container.decode(URL.self, forKey: .imageURL)
            self = .image(url)
        case .video:
            let url = try container.decode(URL.self, forKey: .videoURL)
            let thumbnailURL = try container.decodeIfPresent(URL.self, forKey: .thumbnailURL)
            self = .video(url, thumbnailURL: thumbnailURL)
        case .audio:
            let url = try container.decode(URL.self, forKey: .audioURL)
            let duration = try container.decode(TimeInterval.self, forKey: .duration)
            self = .audio(url, duration: duration)
        case .post:
            let postId = try container.decode(String.self, forKey: .postId)
            self = .post(postId: postId)
        case .story:
            let storyId = try container.decode(String.self, forKey: .storyId)
            self = .story(storyId: storyId)
        case .reel:
            let reelId = try container.decode(String.self, forKey: .reelId)
            self = .reel(reelId: reelId)
        case .like:
            self = .like
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let text):
            try container.encode(ContentType.text, forKey: .type)
            try container.encode(text, forKey: .text)
        case .image(let url):
            try container.encode(ContentType.image, forKey: .type)
            try container.encode(url, forKey: .imageURL)
        case .video(let url, let thumbnailURL):
            try container.encode(ContentType.video, forKey: .type)
            try container.encode(url, forKey: .videoURL)
            if let thumbnailURL = thumbnailURL {
                try container.encode(thumbnailURL, forKey: .thumbnailURL)
            }
        case .audio(let url, let duration):
            try container.encode(ContentType.audio, forKey: .type)
            try container.encode(url, forKey: .audioURL)
            try container.encode(duration, forKey: .duration)
        case .post(let postId):
            try container.encode(ContentType.post, forKey: .type)
            try container.encode(postId, forKey: .postId)
        case .story(let storyId):
            try container.encode(ContentType.story, forKey: .type)
            try container.encode(storyId, forKey: .storyId)
        case .reel(let reelId):
            try container.encode(ContentType.reel, forKey: .type)
            try container.encode(reelId, forKey: .reelId)
        case .like:
            try container.encode(ContentType.like, forKey: .type)
        }
    }
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

