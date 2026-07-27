//
//  Story.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - Story

struct Story: Identifiable, Hashable, Sendable {
    let id: String
    let author: User
    let items: [StoryItem]
    let isViewed: Bool
    let createdAt: Date
    let expiresAt: Date
}

// MARK: - StoryItem

struct StoryItem: Identifiable, Hashable, Sendable {
    let id: String
    let mediaURL: URL
    let type: MediaType
    let duration: TimeInterval
    let createdAt: Date
    let sticker: StoryStickerInfo?

    enum MediaType: String, Sendable, Hashable {
        case image
        case video
    }
}

// MARK: - StoryStickerInfo

struct StoryStickerInfo: Hashable, Sendable {
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
