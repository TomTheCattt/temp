//
//  MockStoryDataSource.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - MockStoryDataSource

actor MockStoryDataSource {

    private var stories: [Story] = MockData.stories

    func fetchStories() async throws -> [Story] {
        try await simulateDelay()
        return stories
    }

    func fetchStoryItems(userId: String) async throws -> [StoryItem] {
        try await simulateDelay(seconds: 0.3)
        guard let story = stories.first(where: { $0.author.id == userId }) else {
            return []
        }
        return story.items
    }

    func markViewed(storyId: String) async throws {
        try await simulateDelay(seconds: 0.1)
        if let index = stories.firstIndex(where: { $0.id == storyId }) {
            let story = stories[index]
            stories[index] = Story(
                id: story.id,
                author: story.author,
                items: story.items.map { item in
                    StoryItem(
                        id: item.id,
                        mediaURL: item.mediaURL,
                        type: item.type,
                        duration: item.duration,
                        createdAt: item.createdAt,
                        sticker: item.sticker
                    )
                },
                isViewed: true,
                createdAt: story.createdAt,
                expiresAt: story.expiresAt
            )
        }
    }

    func createStory(mediaData: Data, type: StoryItem.MediaType, duration: TimeInterval) async throws -> Story {
        try await simulateDelay(seconds: 0.8)

        let currentUser = await (SessionStore.shared.currentUser ?? MockData.currentUser)
        let newItem = StoryItem(
            id: "story_item_\(UUID().uuidString.prefix(8))",
            mediaURL: URL(string: "https://picsum.photos/seed/\(UUID().uuidString.prefix(6))/1080/1920")!,
            type: type,
            duration: duration,
            createdAt: .now,
            sticker: nil
        )

        if let myIndex = stories.firstIndex(where: { $0.author.id == currentUser.id }) {
            let existing = stories[myIndex]
            var updatedItems = existing.items
            updatedItems.append(newItem)
            let updatedStory = Story(
                id: existing.id,
                author: existing.author,
                items: updatedItems,
                isViewed: false,
                createdAt: .now,
                expiresAt: Date(timeIntervalSinceNow: 24 * 3600)
            )
            stories[myIndex] = updatedStory
            return updatedStory
        } else {
            let newStory = Story(
                id: "story_new_\(UUID().uuidString.prefix(8))",
                author: currentUser,
                items: [newItem],
                isViewed: false,
                createdAt: .now,
                expiresAt: Date(timeIntervalSinceNow: 24 * 3600)
            )
            stories.insert(newStory, at: 0)
            return newStory
        }
    }

    func deleteStory(id: String) async throws {
        try await simulateDelay(seconds: 0.3)
        stories.removeAll { $0.id == id }
    }

    // MARK: - Private

    private func simulateDelay(seconds: Double = 0.5) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
