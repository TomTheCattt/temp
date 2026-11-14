//
//  Story.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - Story

nonisolated struct Story: Identifiable, Hashable, Sendable {
    let id: String
    let authorId: String?
    let author: User
    let items: [StoryItem]
    var isViewed: Bool
    let audience: String?
    let viewsCount: Int
    let repliesCount: Int
    let createdAt: Date
    let expiresAt: Date

    init(
        id: String,
        authorId: String? = nil,
        author: User,
        items: [StoryItem],
        isViewed: Bool,
        audience: String? = nil,
        viewsCount: Int = 0,
        repliesCount: Int = 0,
        createdAt: Date,
        expiresAt: Date
    ) {
        self.id = id
        self.authorId = authorId ?? author.id
        self.author = author
        self.items = items
        self.isViewed = isViewed
        self.audience = audience
        self.viewsCount = viewsCount
        self.repliesCount = repliesCount
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
}

// MARK: - StoryItem

nonisolated struct StoryItem: Identifiable, Hashable, Sendable {
    let id: String
    let mediaURL: URL
    let thumbnailURL: URL?
    let type: MediaType
    let duration: TimeInterval
    let sortOrder: Int
    let createdAt: Date
    let sticker: StoryStickerInfo?

    init(
        id: String,
        mediaURL: URL,
        thumbnailURL: URL? = nil,
        type: MediaType,
        duration: TimeInterval,
        sortOrder: Int = 0,
        createdAt: Date,
        sticker: StoryStickerInfo? = nil
    ) {
        self.id = id
        self.mediaURL = mediaURL
        self.thumbnailURL = thumbnailURL
        self.type = type
        self.duration = duration
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.sticker = sticker
    }

    enum MediaType: String, Sendable, Hashable {
        case image
        case video
    }
}

// MARK: - StoryStickerInfo

nonisolated struct StoryStickerInfo: Hashable, Sendable {
    let type: StickerType
    let data: String? // JSON or text payload

    enum StickerType: String, Sendable, Hashable {
        case mention
        case hashtag
        case location
        case poll
        case question
        case link
        case music
    }
}

// MARK: - StoryReply & StoryReaction

nonisolated struct StoryReaction: Identifiable, Hashable, Sendable {
    let id: String
    let emoji: String
    let userId: String
}

nonisolated struct StoryReply: Identifiable, Hashable, Sendable {
    let id: String
    let user: User
    let text: String
    let createdAt: Date
    var reactions: [StoryReaction]

    init(id: String, user: User, text: String, createdAt: Date, reactions: [StoryReaction] = []) {
        self.id = id
        self.user = user
        self.text = text
        self.createdAt = createdAt
        self.reactions = reactions
    }
}
