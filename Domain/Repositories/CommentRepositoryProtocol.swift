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

    /// Fetch replies for a comment.
    func fetchReplies(commentId: String, page: Int, perPage: Int) async throws -> [Comment]

    /// Post a new comment.
    func addComment(postId: String, text: String, parentId: String?) async throws -> Comment

    /// Delete a comment.
    func deleteComment(id: String) async throws

    /// Like a comment.
    func likeComment(id: String) async throws

    /// Unlike a comment.
    func unlikeComment(id: String) async throws
}
