//
//  StoryRepositoryProtocol.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - StoryRepositoryProtocol

protocol StoryRepositoryProtocol: Sendable {

    /// Fetch stories for the home feed bar (users who have active stories).
    func fetchStories() async throws -> [Story]

    /// Fetch story items for a specific user.
    func fetchStoryItems(userId: String) async throws -> [StoryItem]

    /// Create a new story item.
    func createStory(mediaData: Data, type: StoryItem.MediaType, duration: TimeInterval) async throws -> Story

    /// Mark a story as viewed.
    func markViewed(storyId: String) async throws

    /// Delete a story.
    func deleteStory(id: String) async throws
}
