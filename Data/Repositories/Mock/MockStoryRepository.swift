//
//  MockStoryRepository.swift
//  Instagram
//
//  Created by Kiro on 5/8/26.
//

import Foundation

// MARK: - MockStoryRepository

/// Mock implementation of StoryRepositoryProtocol for UI testing with local data.
final class MockStoryRepository: StoryRepositoryProtocol, @unchecked Sendable {

    private let dataSource = MockStoryDataSource()

    func fetchStories() async throws -> [Story] {
        try await dataSource.fetchStories()
    }

    func fetchStoryItems(userId: String) async throws -> [StoryItem] {
        try await dataSource.fetchStoryItems(userId: userId)
    }

    func createStory(mediaData: Data, type: StoryItem.MediaType, duration: TimeInterval) async throws -> Story {
        try await dataSource.createStory(mediaData: mediaData, type: type, duration: duration)
    }

    func markViewed(storyId: String) async throws {
        try await dataSource.markViewed(storyId: storyId)
    }

    func deleteStory(id: String) async throws {
        try await dataSource.deleteStory(id: id)
    }
}
