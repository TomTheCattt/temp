//
//  StoryDTO.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - StoryDTO

/// API response model for Story.
nonisolated struct StoryDTO: Decodable, Sendable {
    let id: String
    let author: UserDTO
    let items: [StoryItemDTO]
    let isViewed: Bool
    let createdAt: String
    let expiresAt: String
}

// MARK: - StoryItemDTO

nonisolated struct StoryItemDTO: Decodable, Sendable {
    let id: String
    let mediaUrl: String
    let type: String // "image" | "video"
    let duration: Double
    let createdAt: String
    let sticker: StoryStickerDTO?
}

// MARK: - StoryStickerDTO

nonisolated struct StoryStickerDTO: Decodable, Sendable {
    let type: String // "mention" | "hashtag" | "location" | "poll" | "question" | "link" | "music"
    let data: String?
}
