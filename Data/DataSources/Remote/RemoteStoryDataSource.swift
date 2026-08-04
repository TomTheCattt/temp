//
//  RemoteStoryDataSource.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - RemoteStoryDataSource

final class RemoteStoryDataSource: @unchecked Sendable {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    // MARK: - Feed

    func fetchStories() async throws -> [Story] {
        let response: StoriesFeedDTO = try await networkService.requestEnvelope(
            StoryEndpoint.feed
        )
        return StoryMapper.toEntityList(response.items)
    }

    // MARK: - User Stories

    func fetchUserStories(userId: String) async throws -> [Story] {
        let response: UserStoriesDTO = try await networkService.requestEnvelope(
            StoryEndpoint.userItems(userId: userId)
        )
        return StoryMapper.toEntityList(response.stories)
    }

    // MARK: - Create

    func createStory(mediaUrl: String, type: String, duration: Double, stickerType: String?, stickerData: String?) async throws -> Story {
        let wrapper: StoryWrapperDTO = try await networkService.requestEnvelope(
            StoryEndpoint.create(mediaUrl: mediaUrl, type: type, duration: duration, stickerType: stickerType, stickerData: stickerData)
        )
        return StoryMapper.toEntity(wrapper.story)
    }

    // MARK: - View

    func markViewed(storyId: String) async throws {
        try await networkService.requestVoid(StoryEndpoint.markViewed(storyId: storyId))
    }

    // MARK: - Delete

    func deleteStory(id: String) async throws {
        try await networkService.requestVoid(StoryEndpoint.delete(id: id))
    }
}
