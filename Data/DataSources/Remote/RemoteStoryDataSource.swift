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

    // MARK: - Comments

    func fetchStoryComments(storyId: String, page: Int, perPage: Int) async throws -> (comments: [Comment], page: Int, perPage: Int, total: Int, hasMore: Bool) {
        let response: PaginatedCommentsDTO = try await networkService.requestEnvelope(
            StoryEndpoint.comments(storyId: storyId, page: page, perPage: perPage)
        )
        return (CommentMapper.toEntityList(response.items), response.page, response.perPage, response.total, response.hasMore)
    }

    func addStoryComment(storyId: String, text: String, parentId: String?) async throws -> Comment {
        let wrapper: CommentWrapperDTO = try await networkService.requestEnvelope(
            StoryEndpoint.addComment(storyId: storyId, text: text, parentId: parentId)
        )
        return CommentMapper.toEntity(wrapper.comment)
    }

    func deleteStoryComment(storyId: String, commentId: String) async throws {
        try await networkService.requestVoid(StoryEndpoint.deleteComment(storyId: storyId, commentId: commentId))
    }

    // MARK: - Replies

    func fetchStoryReplies(storyId: String) async throws -> StoryRepliesResult {
        let wrapper: StoryRepliesResultWrapperDTO = try await networkService.requestEnvelope(
            StoryEndpoint.fetchReplies(storyId: storyId)
        )
        return StoryMapper.toStoryRepliesResult(wrapper.replies)
    }

    func addStoryReply(storyId: String, text: String) async throws -> StoryReply {
        let wrapper: StoryReplyWrapperDTO = try await networkService.requestEnvelope(
            StoryEndpoint.addReply(storyId: storyId, text: text)
        )
        return StoryMapper.toStoryReply(wrapper.reply)
    }

    func deleteStoryReply(replyId: String) async throws {
        try await networkService.requestVoid(StoryEndpoint.deleteReply(replyId: replyId))
    }

    func deleteAllStoryReplies(storyId: String) async throws {
        try await networkService.requestVoid(StoryEndpoint.deleteAllReplies(storyId: storyId))
    }

    func setStoryRepliesEnabled(storyId: String, enabled: Bool) async throws {
        try await networkService.requestVoid(StoryEndpoint.setRepliesEnabled(storyId: storyId, enabled: enabled))
    }
}
