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

    func createStory(mediaData: Data, type: StoryItem.MediaType, duration: TimeInterval) async throws -> Story {
        try await simulateDelay(seconds: 1.0)
        return Story(
            id: "story_new_\(UUID().uuidString.prefix(8))",
            author: MockData.currentUser,
            items: [
                StoryItem(
                    id: "story_item_new",
                    mediaURL: URL(string: "https://picsum.photos/seed/newstory/1080/1920")!,
                    type: type,
                    duration: duration,
                    createdAt: .now,
                    sticker: nil
                )
            ],
            isViewed: false,
            createdAt: .now,
            expiresAt: Date(timeIntervalSinceNow: 24 * 3600)
        )
    }

    func deleteStory(id: String) async throws {
        try await simulateDelay(seconds: 0.3)
    }

    // MARK: - Private

    private func simulateDelay(seconds: Double = 0.5) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
