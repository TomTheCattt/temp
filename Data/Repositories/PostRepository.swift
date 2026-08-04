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

    init(remoteDataSource: RemotePostDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    // MARK: - Feed

    func fetchFeed(page: Int, perPage: Int) async throws -> [Post] {
        try await remoteDataSource.fetchFeed(page: page, perPage: perPage)
    }

    func fetchUserPosts(userId: String, page: Int, perPage: Int) async throws -> [Post] {
        try await remoteDataSource.fetchUserPosts(userId: userId, page: page, perPage: perPage)
    }

    func fetchPost(id: String) async throws -> Post {
        try await remoteDataSource.fetchPost(id: id)
    }

    // MARK: - Create / Delete

    func createPost(caption: String?, mediaData: [Data], location: PostLocation?) async throws -> Post {
        try await remoteDataSource.createPost(caption: caption, mediaData: mediaData, location: location)
    }

    func deletePost(id: String) async throws {
        try await remoteDataSource.deletePost(id: id)
    }

    // MARK: - Like / Save

    func likePost(id: String) async throws {
        try await remoteDataSource.likePost(id: id)
    }

    func unlikePost(id: String) async throws {
        try await remoteDataSource.unlikePost(id: id)
    }

    func savePost(id: String) async throws {
        try await remoteDataSource.savePost(id: id)
    }

    func unsavePost(id: String) async throws {
        try await remoteDataSource.unsavePost(id: id)
    }

    // MARK: - Explore & Saved

    func fetchSavedPosts(page: Int, perPage: Int) async throws -> [Post] {
        try await remoteDataSource.fetchSavedPosts(page: page, perPage: perPage)
    }

    func fetchExplorePosts(page: Int, perPage: Int) async throws -> [Post] {
        try await remoteDataSource.fetchExplorePosts(page: page, perPage: perPage)
    }
}
