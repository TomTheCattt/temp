//
 //  CommentRepositoryProtocol.swift
 //  Instagram
 //
 //  Created by Kiro on 26/7/26.
 //

import Foundation

// MARK: - CommentRepositoryProtocol

protocol CommentRepositoryProtocol: Sendable {

    /// Fetch comments for a post (offset-based pagination).
    func fetchComments(postId: String, page: Int, perPage: Int) async throws -> (comments: [Comment], page: Int, perPage: Int, total: Int, hasMore: Bool)

    /// Fetch comments for a reel (offset-based pagination).
    func fetchReelComments(reelId: String, page: Int, perPage: Int) async throws -> (comments: [Comment], page: Int, perPage: Int, total: Int, hasMore: Bool)

    /// Fetch comments for a story (offset-based pagination).
    func fetchStoryComments(storyId: String, page: Int, perPage: Int) async throws -> (comments: [Comment], page: Int, perPage: Int, total: Int, hasMore: Bool)

    /// Post a new comment on a post (use parentId for replies).
    func addComment(postId: String, text: String, parentId: String?) async throws -> Comment

    /// Post a new comment on a reel (use parentId for replies).
    func addReelComment(reelId: String, text: String, parentId: String?) async throws -> Comment

    /// Post a new comment on a story (use parentId for replies).
    func addStoryComment(storyId: String, text: String, parentId: String?) async throws -> Comment

    /// Delete a comment on a post.
    func deleteComment(postId: String, commentId: String) async throws

    /// Delete a comment on a reel.
    func deleteReelComment(reelId: String, commentId: String) async throws

    /// Delete a comment on a story.
    func deleteStoryComment(storyId: String, commentId: String) async throws
}