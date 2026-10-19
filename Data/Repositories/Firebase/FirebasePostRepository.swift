//
//  FirebasePostRepository.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation

// MARK: - FirebasePostRepository

final class FirebasePostRepository: PostRepositoryProtocol, @unchecked Sendable {

    private let dataSource: FirebasePostDataSource

    init(dataSource: FirebasePostDataSource = FirebasePostDataSource()) {
        self.dataSource = dataSource
    }

    // MARK: - Feed

    func fetchFeed(page: Int, perPage: Int) async throws -> [Post] {
        try await dataSource.fetchFeed(page: page, perPage: perPage)
    }

    func fetchUserPosts(userId: String, page: Int, perPage: Int) async throws -> [Post] {
        try await dataSource.fetchUserPosts(userId: userId, page: page, perPage: perPage)
    }

    func fetchPost(id: String) async throws -> Post {
        try await dataSource.fetchPost(id: id)
    }

    // MARK: - Create / Update / Delete

    func createPost(caption: String?, mediaData: [Data], location: PostLocation?) async throws -> Post {
        try await dataSource.createPost(caption: caption, mediaData: mediaData, location: location)
    }

    func updatePost(id: String, caption: String?, location: PostLocation?) async throws -> Post {
        try await dataSource.updatePost(id: id, caption: caption, location: location)
    }

    func deletePost(id: String) async throws {
        try await dataSource.deletePost(id: id)
    }

    // MARK: - Like / Save

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

    // MARK: - Saved / Explore

    func fetchSavedPosts(page: Int, perPage: Int) async throws -> [Post] {
        try await dataSource.fetchSavedPosts(page: page, perPage: perPage)
    }

    func fetchExplorePosts(page: Int, perPage: Int) async throws -> [Post] {
        try await dataSource.fetchExplorePosts(page: page, perPage: perPage)
    }
}
