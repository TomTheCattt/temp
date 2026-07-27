//
//  PostRepositoryProtocol.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - PostRepositoryProtocol

protocol PostRepositoryProtocol: Sendable {

    /// Fetch the home feed.
    func fetchFeed(page: Int, perPage: Int) async throws -> [Post]

    /// Fetch posts for a user's profile grid.
    func fetchUserPosts(userId: String, page: Int, perPage: Int) async throws -> [Post]

    /// Fetch a single post by ID.
    func fetchPost(id: String) async throws -> Post

    /// Create a new post.
    func createPost(caption: String?, mediaData: [Data], location: PostLocation?) async throws -> Post

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

    /// Fetch saved posts.
    func fetchSavedPosts(page: Int, perPage: Int) async throws -> [Post]

    /// Fetch posts for the Explore grid.
    func fetchExplorePosts(page: Int, perPage: Int) async throws -> [Post]
}
