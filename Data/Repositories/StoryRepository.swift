//
//  StoryRepository.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Alamofire

// MARK: - StoryRepository

final class StoryRepository: StoryRepositoryProtocol, @unchecked Sendable {

    private let remoteDataSource: RemoteStoryDataSource
    private let networkService: NetworkServiceProtocol

    init(
        remoteDataSource: RemoteStoryDataSource,
        networkService: NetworkServiceProtocol
    ) {
        self.remoteDataSource = remoteDataSource
        self.networkService = networkService
    }

    func fetchStories() async throws -> [Story] {
        try await remoteDataSource.fetchStories()
    }

    func fetchStoryItems(userId: String) async throws -> [StoryItem] {
        let stories = try await remoteDataSource.fetchUserStories(userId: userId)
        return stories.flatMap { $0.items }
    }

    func createStory(mediaData: Data, type: StoryItem.MediaType, duration: TimeInterval) async throws -> Story {
        // Step 1: Upload media
        let mediaType = type == .video ? "VIDEO" : "IMAGE"
        let uploadEndpoint = type == .video ? UploadEndpoint.video : UploadEndpoint.image

        let uploadResponse: UploadImageResponseDTO = try await networkService.upload(uploadEndpoint) { formData in
            let mimeType = type == .video ? "video/mp4" : "image/jpeg"
            let fileName = type == .video ? "story.mp4" : "story.jpg"
            formData.append(mediaData, withName: "file", fileName: fileName, mimeType: mimeType)
        }

        // Step 2: Create story with uploaded URL
        return try await remoteDataSource.createStory(
            mediaUrl: uploadResponse.url,
            type: mediaType,
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
