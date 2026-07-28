//
//  MockCommentDataSource.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - MockCommentDataSource

final class MockCommentDataSource: Sendable {

    func fetchComments(postId: String, page: Int, perPage: Int) async throws -> [Comment] {
        try await simulateDelay()
        let start = (page - 1) * perPage
        let end = min(start + perPage, MockData.comments.count)
        guard start < end else { return [] }
        return Array(MockData.comments[start..<end])
    }

    func fetchReplies(commentId: String, page: Int, perPage: Int) async throws -> [Comment] {
        try await simulateDelay()
        return [] // No nested replies in mock for now
    }

    func addComment(postId: String, text: String, parentId: String?) async throws -> Comment {
        try await simulateDelay(seconds: 0.4)
        return Comment(
            id: "comment_\(UUID().uuidString.prefix(8))",
            postId: postId,
            author: MockData.currentUser,
            text: text,
            likesCount: 0,
            isLiked: false,
            replies: [],
            parentId: parentId,
            createdAt: .now
        )
    }

    func deleteComment(id: String) async throws {
        try await simulateDelay(seconds: 0.3)
    }

    func likeComment(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
    }

    func unlikeComment(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
    }

    // MARK: - Private

    private func simulateDelay(seconds: Double = 0.5) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
