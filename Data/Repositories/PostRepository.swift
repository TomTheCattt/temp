//
//  PostRepository.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - PostRepository

final class PostRepository: PostRepositoryProtocol, @unchecked Sendable {

    private let remoteDataSource: RemotePostDataSource
    private let mockDataSource: MockPostDataSource

    init(
        remoteDataSource: RemotePostDataSource,
        mockDataSource: MockPostDataSource = MockPostDataSource()
    ) {
        self.remoteDataSource = remoteDataSource
        self.mockDataSource = mockDataSource
    }

    // MARK: - Feed

    func fetchFeed(page: Int, perPage: Int) async throws -> [Post] {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchFeed(page: page, perPage: perPage)
        }
        return try await remoteDataSource.fetchFeed(page: page, perPage: perPage)
    }

    func fetchUserPosts(userId: String, page: Int, perPage: Int) async throws -> [Post] {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchUserPosts(userId: userId, page: page, perPage: perPage)
        }
        return try await remoteDataSource.fetchUserPosts(userId: userId, page: page, perPage: perPage)
    }

    func fetchPost(id: String) async throws -> Post {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchPost(id: id)
        }
        return try await remoteDataSource.fetchPost(id: id)
    }

    // MARK: - Create / Delete

    func createPost(caption: String?, mediaData: [Data], location: PostLocation?) async throws -> Post {
        guard !AppConfig.shared.isMockAPI else {
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
        return try await remoteDataSource.createPost(caption: caption, mediaData: mediaData, location: location)
    }

    func deletePost(id: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            try await Task.sleep(nanoseconds: 300_000_000)
            return
        }
        try await remoteDataSource.deletePost(id: id)
    }

    // MARK: - Like / Save

    func likePost(id: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.likePost(id: id)
        }
        try await remoteDataSource.likePost(id: id)
    }

    func unlikePost(id: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.unlikePost(id: id)
        }
        try await remoteDataSource.unlikePost(id: id)
    }

    func savePost(id: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.savePost(id: id)
        }
        try await remoteDataSource.savePost(id: id)
    }

    func unsavePost(id: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.unsavePost(id: id)
        }
        try await remoteDataSource.unsavePost(id: id)
    }

    // MARK: - Explore & Saved

    func fetchSavedPosts(page: Int, perPage: Int) async throws -> [Post] {
        guard !AppConfig.shared.isMockAPI else {
            try await Task.sleep(nanoseconds: 500_000_000)
            return MockData.posts.filter { $0.isSaved }
        }
        return try await remoteDataSource.fetchSavedPosts(page: page, perPage: perPage)
    }

    func fetchExplorePosts(page: Int, perPage: Int) async throws -> [Post] {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchExplorePosts(page: page, perPage: perPage)
        }
        return try await remoteDataSource.fetchExplorePosts(page: page, perPage: perPage)
    }
}
