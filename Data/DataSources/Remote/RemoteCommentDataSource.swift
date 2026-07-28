//
//  RemoteCommentDataSource.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - RemoteCommentDataSource

final class RemoteCommentDataSource: Sendable {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func fetchComments(postId: String, page: Int, perPage: Int) async throws -> [Comment] {
        let response: PaginatedResponseDTO<CommentDTO> = try await networkService.request(
            CommentEndpoint.list(postId: postId, page: page, perPage: perPage)
        )
        return CommentMapper.toEntityList(response.items)
    }

    func fetchReplies(commentId: String, page: Int, perPage: Int) async throws -> [Comment] {
        let response: PaginatedResponseDTO<CommentDTO> = try await networkService.request(
            CommentEndpoint.replies(commentId: commentId, page: page, perPage: perPage)
        )
        return CommentMapper.toEntityList(response.items)
    }

    func addComment(postId: String, text: String, parentId: String?) async throws -> Comment {
        let dto: CommentDTO = try await networkService.request(
            CommentEndpoint.add(postId: postId, text: text, parentId: parentId)
        )
        return CommentMapper.toEntity(dto)
    }

    func deleteComment(id: String) async throws {
        try await networkService.requestVoid(CommentEndpoint.delete(id: id))
    }

    func likeComment(id: String) async throws {
        try await networkService.requestVoid(CommentEndpoint.like(id: id))
    }

    func unlikeComment(id: String) async throws {
        try await networkService.requestVoid(CommentEndpoint.unlike(id: id))
    }
}
