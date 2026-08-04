//
//  StoryDTO.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - StoryDTO

/// API response model for Story. Matches BE response format.
nonisolated struct StoryDTO: Decodable, Sendable {
    let id: String
    let authorId: String
    let createdAt: String
    let expiresAt: String
    let author: UserDTO?     // Present in feed, absent in user-specific items
    let items: [StoryItemDTO]
    let views: [StoryViewDTO]?  // Array of views; non-empty means current user has viewed
}

// MARK: - StoryItemDTO

nonisolated struct StoryItemDTO: Decodable, Sendable {
    let id: String
    let storyId: String?
    let mediaUrl: String
    let type: String            // "IMAGE" | "VIDEO" (uppercase from BE)
    let duration: Double
    let sortOrder: Int?
    let stickerType: String?    // "poll" | "question" | "mention" | "hashtag" | "location" | "link" | "music"
    let stickerData: String?    // JSON string
    let createdAt: String
}

// MARK: - StoryViewDTO

nonisolated struct StoryViewDTO: Decodable, Sendable {
    let id: String
}

// MARK: - StoryWrapperDTO

/// Wrapper for single story creation response: `{ "story": {...} }` inside data envelope.
nonisolated struct StoryWrapperDTO: Decodable, Sendable {
    let story: StoryDTO
}

// MARK: - StoriesFeedDTO

/// Wrapper for stories feed response: `{ "items": [...] }` inside data envelope.
nonisolated struct StoriesFeedDTO: Decodable, Sendable {
    let items: [StoryDTO]
}

// MARK: - UserStoriesDTO

/// Wrapper for user-specific stories: `{ "stories": [...] }` inside data envelope.
nonisolated struct UserStoriesDTO: Decodable, Sendable {
    let stories: [StoryDTO]
}
