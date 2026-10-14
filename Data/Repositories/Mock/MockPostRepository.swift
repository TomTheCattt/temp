//
//  MockPostRepository.swift
//  Instagram
//
//  Created by Kiro on 5/8/26.
//

import Foundation

// MARK: - MockPostRepository

/// Mock implementation of PostRepositoryProtocol for UI testing with local data.
final class MockPostRepository: PostRepositoryProtocol, @unchecked Sendable {

    private let dataSource = MockPostDataSource()

    func fetchFeed(page: Int, perPage: Int) async throws -> [Post] {
        try await dataSource.fetchFeed(page: page, perPage: perPage)
    }

    func fetchUserPosts(userId: String, page: Int, perPage: Int) async throws -> [Post] {
        try await dataSource.fetchUserPosts(userId: userId, page: page, perPage: perPage)
    }

    func fetchPost(id: String) async throws -> Post {
        try await dataSource.fetchPost(id: id)
    }

    func createPost(caption: String?, mediaData: [Data], location: PostLocation?) async throws -> Post {
        try await dataSource.createPost(caption: caption, mediaData: mediaData, location: location)
    }

    func updatePost(id: String, caption: String?, location: PostLocation?) async throws -> Post {
        try await Task.sleep(nanoseconds: 500_000_000)
        // Return the matching mock post with updated editable fields applied.
        let base = MockData.posts.first(where: { $0.id == id }) ?? MockData.posts.first!
        return Post(
            id: base.id,
            author: base.author,
            caption: caption,
            mediaItems: base.mediaItems,
            location: location,
            likesCount: base.likesCount,
            commentsCount: base.commentsCount,
            createdAt: base.createdAt,
            isLiked: base.isLiked,
            isSaved: base.isSaved,
            isSponsored: base.isSponsored
        )
    }

    func deletePost(id: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }

    func likePost(id: String) async throws {
        try await dataSource.likePost(id: id)
    }

    func unlikePost(id: String) async throws {
        try await dataSource.unlikePost(id: id)
    }

    func savePost(id: String) async throws {
        try await dataSource.savePost(id: id)
    }

    func unsavePost(id: String) async throws {
        try await dataSource.unsavePost(id: id)
    }

    func fetchSavedPosts(page: Int, perPage: Int) async throws -> [Post] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return Array(MockData.posts.prefix(3))
    }

    func fetchExplorePosts(page: Int, perPage: Int) async throws -> [Post] {
        try await dataSource.fetchExplorePosts(page: page, perPage: perPage)
    }
}
