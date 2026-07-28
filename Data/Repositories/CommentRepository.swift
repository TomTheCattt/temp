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
    private let mockDataSource: MockCommentDataSource

    init(
        remoteDataSource: RemoteCommentDataSource,
        mockDataSource: MockCommentDataSource = MockCommentDataSource()
    ) {
        self.remoteDataSource = remoteDataSource
        self.mockDataSource = mockDataSource
    }

    func fetchComments(postId: String, page: Int, perPage: Int) async throws -> [Comment] {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchComments(postId: postId, page: page, perPage: perPage)
        }
        return try await remoteDataSource.fetchComments(postId: postId, page: page, perPage: perPage)
    }

    func fetchReplies(commentId: String, page: Int, perPage: Int) async throws -> [Comment] {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchReplies(commentId: commentId, page: page, perPage: perPage)
        }
        return try await remoteDataSource.fetchReplies(commentId: commentId, page: page, perPage: perPage)
    }

    func addComment(postId: String, text: String, parentId: String?) async throws -> Comment {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.addComment(postId: postId, text: text, parentId: parentId)
        }
        return try await remoteDataSource.addComment(postId: postId, text: text, parentId: parentId)
    }

    func deleteComment(id: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.deleteComment(id: id)
        }
        try await remoteDataSource.deleteComment(id: id)
    }

    func likeComment(id: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.likeComment(id: id)
        }
        try await remoteDataSource.likeComment(id: id)
    }

    func unlikeComment(id: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.unlikeComment(id: id)
        }
        try await remoteDataSource.unlikeComment(id: id)
    }
}
