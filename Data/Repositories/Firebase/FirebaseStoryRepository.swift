//
//  FirebaseStoryRepository.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation

// MARK: - FirebaseStoryRepository

final class FirebaseStoryRepository: StoryRepositoryProtocol, @unchecked Sendable {

    private let dataSource: FirebaseStoryDataSource

    init(dataSource: FirebaseStoryDataSource = FirebaseStoryDataSource()) {
        self.dataSource = dataSource
    }

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
