//
//  PostRepository.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - PostRepository

final class PostRepository: PostRepositoryProtocol, @unchecked Sendable {

    private let mockDataSource: MockPostDataSource

    init(mockDataSource: MockPostDataSource = MockPostDataSource()) {
        self.mockDataSource = mockDataSource
    }

    func fetchFeed(page: Int, perPage: Int) async throws -> [Post] {
        try await mockDataSource.fetchFeed(page: page, perPage: perPage)
    }

    func fetchUserPosts(userId: String, page: Int, perPage: Int) async throws -> [Post] {
        try await mockDataSource.fetchUserPosts(userId: userId, page: page, perPage: perPage)
    }

    func fetchPost(id: String) async throws -> Post {
        try await mockDataSource.fetchPost(id: id)
    }

    func createPost(caption: String?, mediaData: [Data], location: PostLocation?) async throws -> Post {
        // Mock: return a new fake post
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return Post(
            id: "post_new_\(UUID().uuidString.prefix(8))",
            author: MockData.currentUser,
            caption: caption,
            mediaItems: [],
            location: location,
            likesCount: 0,
            commentsCount: 0,
            createdAt: .now,
            isLiked: false,
            isSaved: false,
            isSponsored: false
        )
    }

    func deletePost(id: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }

    func likePost(id: String) async throws {
        try await mockDataSource.likePost(id: id)
    }

    func unlikePost(id: String) async throws {
        try await mockDataSource.unlikePost(id: id)
    }

    func savePost(id: String) async throws {
        try await mockDataSource.savePost(id: id)
    }

    func unsavePost(id: String) async throws {
        try await mockDataSource.unsavePost(id: id)
    }

    func fetchSavedPosts(page: Int, perPage: Int) async throws -> [Post] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return MockData.posts.filter { $0.isSaved }
    }

    func fetchExplorePosts(page: Int, perPage: Int) async throws -> [Post] {
        try await mockDataSource.fetchExplorePosts(page: page, perPage: perPage)
    }
}
