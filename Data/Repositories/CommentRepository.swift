//
//  CommentRepository.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - CommentRepository

final class CommentRepository: CommentRepositoryProtocol, @unchecked Sendable {

    private let remoteDataSource: RemoteCommentDataSource

    init(remoteDataSource: RemoteCommentDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchComments(postId: String, page: Int, perPage: Int) async throws -> [Comment] {
        try await remoteDataSource.fetchComments(postId: postId, page: page, perPage: perPage)
    }

    func addComment(postId: String, text: String, parentId: String?) async throws -> Comment {
        try await remoteDataSource.addComment(postId: postId, text: text, parentId: parentId)
    }

    func deleteComment(postId: String, commentId: String) async throws {
        try await remoteDataSource.deleteComment(postId: postId, commentId: commentId)
    }

    func likeComment(postId: String, commentId: String) async throws {
        try await remoteDataSource.likeComment(postId: postId, commentId: commentId)
    }

    func unlikeComment(postId: String, commentId: String) async throws {
        try await remoteDataSource.unlikeComment(postId: postId, commentId: commentId)
    }
}
