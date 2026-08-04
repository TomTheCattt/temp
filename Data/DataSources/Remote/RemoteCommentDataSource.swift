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

    // MARK: - Fetch

    func fetchComments(postId: String, page: Int, perPage: Int) async throws -> [Comment] {
        let response: PaginatedCommentsDTO = try await networkService.requestEnvelope(
            CommentEndpoint.list(postId: postId, page: page, perPage: perPage)
        )
        return CommentMapper.toEntityList(response.items)
    }

    // MARK: - Add

    func addComment(postId: String, text: String, parentId: String?) async throws -> Comment {
        let wrapper: CommentWrapperDTO = try await networkService.requestEnvelope(
            CommentEndpoint.add(postId: postId, text: text, parentId: parentId)
        )
        return CommentMapper.toEntity(wrapper.comment)
    }

    // MARK: - Like / Unlike

    func likeComment(postId: String, commentId: String) async throws {
        try await networkService.requestVoid(CommentEndpoint.like(postId: postId, commentId: commentId))
    }

    func unlikeComment(postId: String, commentId: String) async throws {
        try await networkService.requestVoid(CommentEndpoint.unlike(postId: postId, commentId: commentId))
    }

    // MARK: - Delete

    func deleteComment(postId: String, commentId: String) async throws {
        try await networkService.requestVoid(CommentEndpoint.delete(postId: postId, commentId: commentId))
    }
}
