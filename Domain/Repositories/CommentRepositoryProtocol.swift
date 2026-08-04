//
//  CommentRepositoryProtocol.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - CommentRepositoryProtocol

protocol CommentRepositoryProtocol: Sendable {

    /// Fetch comments for a post.
    func fetchComments(postId: String, page: Int, perPage: Int) async throws -> [Comment]

    /// Post a new comment (use parentId for replies).
    func addComment(postId: String, text: String, parentId: String?) async throws -> Comment

    /// Delete a comment.
    func deleteComment(postId: String, commentId: String) async throws

    /// Like a comment.
    func likeComment(postId: String, commentId: String) async throws

    /// Unlike a comment.
    func unlikeComment(postId: String, commentId: String) async throws
}
