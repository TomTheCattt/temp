//
//  MockStoryDataSource.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - MockStoryDataSource

final class MockStoryDataSource: Sendable {

    func fetchStories() async throws -> [Story] {
        try await simulateDelay()
        return MockData.stories
    }

    func fetchStoryItems(userId: String) async throws -> [StoryItem] {
        try await simulateDelay(seconds: 0.3)
        guard let story = MockData.stories.first(where: { $0.author.id == userId }) else {
            return []
        }
        return story.items
    }

    func markViewed(storyId: String) async throws {
        try await simulateDelay(seconds: 0.1)
    }

    // MARK: - Private

    private func simulateDelay(seconds: Double = 0.5) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
