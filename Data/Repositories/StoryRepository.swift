//
//  StoryRepository.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - StoryRepository

final class StoryRepository: StoryRepositoryProtocol, @unchecked Sendable {

    private let remoteDataSource: RemoteStoryDataSource
    private let mockDataSource: MockStoryDataSource

    init(
        remoteDataSource: RemoteStoryDataSource,
        mockDataSource: MockStoryDataSource = MockStoryDataSource()
    ) {
        self.remoteDataSource = remoteDataSource
        self.mockDataSource = mockDataSource
    }

    func fetchStories() async throws -> [Story] {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchStories()
        }
        return try await remoteDataSource.fetchStories()
    }

    func fetchStoryItems(userId: String) async throws -> [StoryItem] {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchStoryItems(userId: userId)
        }
        return try await remoteDataSource.fetchStoryItems(userId: userId)
    }

    func createStory(mediaData: Data, type: StoryItem.MediaType, duration: TimeInterval) async throws -> Story {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.createStory(mediaData: mediaData, type: type, duration: duration)
        }
        return try await remoteDataSource.createStory(mediaData: mediaData, type: type, duration: duration)
    }

    func markViewed(storyId: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.markViewed(storyId: storyId)
        }
        try await remoteDataSource.markViewed(storyId: storyId)
    }

    func deleteStory(id: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.deleteStory(id: id)
        }
        try await remoteDataSource.deleteStory(id: id)
    }
}
