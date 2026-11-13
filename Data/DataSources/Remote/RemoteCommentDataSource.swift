//
//  RemoteCommentDataSource.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - RemoteCommentDataSource

final class RemoteCommentDataSource: @unchecked Sendable {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    // MARK: - Fetch (Post Comments) - offset pagination

    func fetchComments(postId: String, page: Int, perPage: Int) async throws -> (comments: [Comment], page: Int, perPage: Int, total: Int, hasMore: Bool) {
        let response: PaginatedCommentsDTO = try await networkService.requestEnvelope(
            CommentEndpoint.list(postId: postId, page: page, perPage: perPage)
        )
        return (CommentMapper.toEntityList(response.items), response.page, response.perPage, response.total, response.hasMore)
    }

    // MARK: - Fetch (Reel Comments) - offset pagination

    func fetchReelComments(reelId: String, page: Int, perPage: Int) async throws -> (comments: [Comment], page: Int, perPage: Int, total: Int, hasMore: Bool) {
        let response: PaginatedCommentsDTO = try await networkService.requestEnvelope(
            CommentEndpoint.listReelComments(reelId: reelId, page: page, perPage: perPage)
        )
        return (CommentMapper.toEntityList(response.items), response.page, response.perPage, response.total, response.hasMore)
    }

    // MARK: - Fetch (Story Comments) - offset pagination

    func fetchStoryComments(storyId: String, page: Int, perPage: Int) async throws -> (comments: [Comment], page: Int, perPage: Int, total: Int, hasMore: Bool) {
        let response: PaginatedCommentsDTO = try await networkService.requestEnvelope(
            CommentEndpoint.listStoryComments(storyId: storyId, page: page, perPage: perPage)
        )
        return (CommentMapper.toEntityList(response.items), response.page, response.perPage, response.total, response.hasMore)
    }

    // MARK: - Add (Post Comments)

    func addComment(postId: String, text: String, parentId: String?) async throws -> Comment {
        let wrapper: CommentWrapperDTO = try await networkService.requestEnvelope(
            CommentEndpoint.add(postId: postId, text: text, parentId: parentId)
        )
        return CommentMapper.toEntity(wrapper.comment)
    }

    // MARK: - Add (Reel Comments)

    func addReelComment(reelId: String, text: String, parentId: String?) async throws -> Comment {
        let wrapper: CommentWrapperDTO = try await networkService.requestEnvelope(
            CommentEndpoint.addReelComment(reelId: reelId, text: text, parentId: parentId)
        )
        return CommentMapper.toEntity(wrapper.comment)
    }

    // MARK: - Add (Story Comments)

    func addStoryComment(storyId: String, text: String, parentId: String?) async throws -> Comment {
        let wrapper: CommentWrapperDTO = try await networkService.requestEnvelope(
            CommentEndpoint.addStoryComment(storyId: storyId, text: text, parentId: parentId)
        )
        return CommentMapper.toEntity(wrapper.comment)
    }

    // MARK: - Delete (Post Comments)

    func deleteComment(postId: String, commentId: String) async throws {
        try await networkService.requestVoid(CommentEndpoint.delete(postId: postId, commentId: commentId))
    }

    // MARK: - Delete (Reel Comments)

    func deleteReelComment(reelId: String, commentId: String) async throws {
        try await networkService.requestVoid(CommentEndpoint.deleteReelComment(reelId: reelId, commentId: commentId))
    }

    // MARK: - Delete (Story Comments)

    func deleteStoryComment(storyId: String, commentId: String) async throws {
        try await networkService.requestVoid(CommentEndpoint.deleteStoryComment(storyId: storyId, commentId: commentId))
    }
}
