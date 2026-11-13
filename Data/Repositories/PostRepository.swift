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

    func fetchFeed(cursor: String?, perPage: Int) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool) {
        try await remoteDataSource.fetchFeed(cursor: cursor, perPage: perPage)
    }

    func fetchUserPosts(userId: String, cursor: String?, perPage: Int) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool) {
        try await remoteDataSource.fetchUserPosts(userId: userId, cursor: cursor, perPage: perPage)
    }

    func fetchPost(id: String) async throws -> Post {
        try await remoteDataSource.fetchPost(id: id)
    }

    // MARK: - Create / Delete

    func createPost(caption: String?, mediaData: [Data], location: PostLocation?) async throws -> Post {
        try await remoteDataSource.createPost(caption: caption, mediaData: mediaData, location: location)
    }

    func updatePost(id: String, caption: String?, location: PostLocation?) async throws -> Post {
        try await remoteDataSource.updatePost(id: id, caption: caption, location: location)
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

    func fetchSavedPosts(cursor: String?, perPage: Int) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool) {
        try await remoteDataSource.fetchSavedPosts(cursor: cursor, perPage: perPage)
    }

    func fetchExplorePosts(cursor: String?, perPage: Int) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool) {
        try await remoteDataSource.fetchExplorePosts(cursor: cursor, perPage: perPage)
    }

    // MARK: - Comments

    func fetchComments(postId: String, page: Int, perPage: Int) async throws -> (comments: [Comment], page: Int, perPage: Int, total: Int, hasMore: Bool) {
        try await remoteDataSource.fetchComments(postId: postId, page: page, perPage: perPage)
    }

    func addComment(postId: String, text: String, parentId: String?) async throws -> Comment {
        try await remoteDataSource.addComment(postId: postId, text: text, parentId: parentId)
    }
}
