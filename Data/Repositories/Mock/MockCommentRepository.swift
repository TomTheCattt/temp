//
//  MockCommentRepository.swift
//  Instagram
//
//  Created by Kiro on 5/8/26.
//

import Foundation

// MARK: - MockCommentRepository

/// Mock implementation of CommentRepositoryProtocol for UI testing with local data.
final class MockCommentRepository: CommentRepositoryProtocol, @unchecked Sendable {

    private let dataSource = MockCommentDataSource()

    func fetchComments(postId: String, page: Int, perPage: Int) async throws -> [Comment] {
        try await dataSource.fetchComments(postId: postId, page: page, perPage: perPage)
    }

    func addComment(postId: String, text: String, parentId: String?) async throws -> Comment {
        try await dataSource.addComment(postId: postId, text: text, parentId: parentId)
    }

    func deleteComment(postId: String, commentId: String) async throws {
        try await dataSource.deleteComment(id: commentId)
    }

    func likeComment(postId: String, commentId: String) async throws {
        try await dataSource.likeComment(id: commentId)
    }

    func unlikeComment(postId: String, commentId: String) async throws {
        try await dataSource.unlikeComment(id: commentId)
    }
}
