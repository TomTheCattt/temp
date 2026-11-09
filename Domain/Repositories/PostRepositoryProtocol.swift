//
//  PostRepositoryProtocol.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - PostRepositoryProtocol

protocol PostRepositoryProtocol: Sendable {

    /// Fetch the home feed with cursor-based pagination.
    /// - Parameters:
    ///   - cursor: ISO timestamp cursor for pagination (nil for first page)
    ///   - perPage: Number of items per page (default 20)
    /// - Returns: Tuple of (posts, nextCursor, hasMore)
    func fetchFeed(cursor: String?, perPage: Int) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool)

    /// Fetch posts for a user's profile grid with cursor-based pagination.
    func fetchUserPosts(userId: String, cursor: String?, perPage: Int) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool)

    /// Fetch a single post by ID.
    func fetchPost(id: String) async throws -> Post

    /// Create a new post.
    func createPost(caption: String?, mediaData: [Data], location: PostLocation?) async throws -> Post

    /// Update an existing post's editable fields (caption / location).
    /// Media is immutable after creation, matching Instagram behavior.
    func updatePost(id: String, caption: String?, location: PostLocation?) async throws -> Post

    /// Delete a post.
    func deletePost(id: String) async throws

    /// Like a post.
    func likePost(id: String) async throws

    /// Unlike a post.
    func unlikePost(id: String) async throws

    /// Save a post (bookmark).
    func savePost(id: String) async throws

    /// Unsave a post.
    func unsavePost(id: String) async throws

    /// Fetch saved posts with cursor-based pagination.
    func fetchSavedPosts(cursor: String?, perPage: Int) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool)

    /// Fetch posts for the Explore grid with cursor-based pagination.
    func fetchExplorePosts(cursor: String?, perPage: Int) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool)
}
