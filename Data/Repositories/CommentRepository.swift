//
 //  CommentRepository.swift
 //  Instagram
 //
 //  Created by Kiro on 28/7/26.
 //

import Foundation

// MARK: - CommentRepository

final class CommentRepository: CommentRepositoryProtocol, @unchecked Sendable {

    private let remoteDataSource: RemoteCommentDataSource

    init(remoteDataSource: RemoteCommentDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    // MARK: - Post Comments (offset pagination)

    func fetchComments(postId: String, page: Int, perPage: Int) async throws -> (comments: [Comment], page: Int, perPage: Int, total: Int, hasMore: Bool) {
        try await remoteDataSource.fetchComments(postId: postId, page: page, perPage: perPage)
    }

    func addComment(postId: String, text: String, parentId: String?) async throws -> Comment {
        try await remoteDataSource.addComment(postId: postId, text: text, parentId: parentId)
    }

    func deleteComment(postId: String, commentId: String) async throws {
        try await remoteDataSource.deleteComment(postId: postId, commentId: commentId)
    }

    // MARK: - Reel Comments (offset pagination)

    func fetchReelComments(reelId: String, page: Int, perPage: Int) async throws -> (comments: [Comment], page: Int, perPage: Int, total: Int, hasMore: Bool) {
        try await remoteDataSource.fetchReelComments(reelId: reelId, page: page, perPage: perPage)
    }

    func addReelComment(reelId: String, text: String, parentId: String?) async throws -> Comment {
        try await remoteDataSource.addReelComment(reelId: reelId, text: text, parentId: parentId)
    }

    func deleteReelComment(reelId: String, commentId: String) async throws {
        try await remoteDataSource.deleteReelComment(reelId: reelId, commentId: commentId)
    }

    // MARK: - Story Comments (offset pagination)

    func fetchStoryComments(storyId: String, page: Int, perPage: Int) async throws -> (comments: [Comment], page: Int, perPage: Int, total: Int, hasMore: Bool) {
        try await remoteDataSource.fetchStoryComments(storyId: storyId, page: page, perPage: perPage)
    }

    func addStoryComment(storyId: String, text: String, parentId: String?) async throws -> Comment {
        try await remoteDataSource.addStoryComment(storyId: storyId, text: text, parentId: parentId)
    }

    func deleteStoryComment(storyId: String, commentId: String) async throws {
        try await remoteDataSource.deleteStoryComment(storyId: storyId, commentId: commentId)
    }
}