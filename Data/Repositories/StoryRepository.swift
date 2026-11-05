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
    private let uploadDataSource: RemoteUploadDataSource

    init(
        remoteDataSource: RemoteStoryDataSource,
        uploadDataSource: RemoteUploadDataSource
    ) {
        self.remoteDataSource = remoteDataSource
        self.uploadDataSource = uploadDataSource
    }

    func fetchStories() async throws -> [Story] {
        try await remoteDataSource.fetchStories()
    }

    func fetchStoryItems(userId: String) async throws -> [StoryItem] {
        let stories = try await remoteDataSource.fetchUserStories(userId: userId)
        return stories.flatMap { $0.items }
    }

    func createStory(mediaData: Data, type: StoryItem.MediaType, duration: TimeInterval) async throws -> Story {
        // Step 1: Upload media using presigned URL
        let uploadResult = try await uploadDataSource.upload(
            data: mediaData,
            category: type == .video ? .story : .story,
            filename: type == .video ? "story.mp4" : "story.jpg"
        )

        // Step 2: Create story with uploaded URL
        return try await remoteDataSource.createStory(
            mediaUrl: uploadResult.url,
            type: type == .video ? "VIDEO" : "IMAGE",
            duration: duration,
            stickerType: nil,
            stickerData: nil
        )
    }

    func markViewed(storyId: String) async throws {
        try await remoteDataSource.markViewed(storyId: storyId)
    }

    func deleteStory(id: String) async throws {
        try await remoteDataSource.deleteStory(id: id)
    }
}