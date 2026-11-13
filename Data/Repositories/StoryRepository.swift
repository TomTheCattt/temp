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
        let category: RemoteUploadDataSource.UploadCategory = type == .video ? .story : .story
        let uploadResult = try await uploadDataSource.uploadPresigned(
            data: mediaData,
            category: category
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

    // MARK: - Comments

    func fetchStoryComments(storyId: String, page: Int, perPage: Int) async throws -> (comments: [Comment], page: Int, perPage: Int, total: Int, hasMore: Bool) {
        try await remoteDataSource.fetchStoryComments(storyId: storyId, page: page, perPage: perPage)
    }

    func addStoryComment(storyId: String, text: String, parentId: String?) async throws -> Comment {
        try await remoteDataSource.addStoryComment(storyId: storyId, text: text, parentId: parentId)
    }

    func deleteStoryComment(storyId: String, commentId: String) async throws {
        try await remoteDataSource.deleteStoryComment(storyId: storyId, commentId: commentId)
    }

    // MARK: - Replies

    func fetchStoryReplies(storyId: String) async throws -> StoryRepliesResult {
        try await remoteDataSource.fetchStoryReplies(storyId: storyId)
    }

    func replyToStory(storyId: String, text: String) async throws -> StoryReply {
        try await remoteDataSource.addStoryReply(storyId: storyId, text: text)
    }

    func deleteStoryReply(replyId: String) async throws {
        try await remoteDataSource.deleteStoryReply(replyId: replyId)
    }

    func deleteAllStoryReplies(storyId: String) async throws {
        try await remoteDataSource.deleteAllStoryReplies(storyId: storyId)
    }

    func setStoryRepliesEnabled(storyId: String, enabled: Bool) async throws {
        try await remoteDataSource.setStoryRepliesEnabled(storyId: storyId, enabled: enabled)
    }
}