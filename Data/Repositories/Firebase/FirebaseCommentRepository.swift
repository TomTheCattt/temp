//
//  FirebaseCommentRepository.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation

// MARK: - FirebaseCommentRepository

final class FirebaseCommentRepository: CommentRepositoryProtocol, @unchecked Sendable {

    private let dataSource: FirebaseCommentDataSource

    init(dataSource: FirebaseCommentDataSource = FirebaseCommentDataSource()) {
        self.dataSource = dataSource
    }

    func fetchComments(postId: String, page: Int, perPage: Int) async throws -> [Comment] {
        try await dataSource.fetchComments(postId: postId, page: page, perPage: perPage)
    }

    func addComment(postId: String, text: String, parentId: String?) async throws -> Comment {
        try await dataSource.addComment(postId: postId, text: text, parentId: parentId)
    }

    func deleteComment(postId: String, commentId: String) async throws {
        try await dataSource.deleteComment(postId: postId, commentId: commentId)
    }

    func likeComment(postId: String, commentId: String) async throws {
        try await dataSource.likeComment(postId: postId, commentId: commentId)
    }

    func unlikeComment(postId: String, commentId: String) async throws {
        try await dataSource.unlikeComment(postId: postId, commentId: commentId)
    }
}
