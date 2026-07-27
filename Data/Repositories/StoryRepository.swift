//
//  StoryRepository.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - StoryRepository

final class StoryRepository: StoryRepositoryProtocol, @unchecked Sendable {

    private let mockDataSource: MockStoryDataSource

    init(mockDataSource: MockStoryDataSource = MockStoryDataSource()) {
        self.mockDataSource = mockDataSource
    }

    func fetchStories() async throws -> [Story] {
        try await mockDataSource.fetchStories()
    }

    func fetchStoryItems(userId: String) async throws -> [StoryItem] {
        try await mockDataSource.fetchStoryItems(userId: userId)
    }

    func createStory(mediaData: Data, type: StoryItem.MediaType, duration: TimeInterval) async throws -> Story {
        try await Task.sleep(nanoseconds: 800_000_000)
        return Story(
            id: "story_new_\(UUID().uuidString.prefix(8))",
            author: MockData.currentUser,
            items: [],
            isViewed: false,
            createdAt: .now,
            expiresAt: Date(timeIntervalSinceNow: 24 * 3600)
        )
    }

    func markViewed(storyId: String) async throws {
        try await mockDataSource.markViewed(storyId: storyId)
    }

    func deleteStory(id: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }
}
