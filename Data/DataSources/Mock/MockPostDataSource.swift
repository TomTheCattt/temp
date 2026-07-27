//
//  MockPostDataSource.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - MockPostDataSource

final class MockPostDataSource: Sendable {

    func fetchFeed(page: Int, perPage: Int) async throws -> [Post] {
        try await simulateDelay()
        let start = (page - 1) * perPage
        let end = min(start + perPage, MockData.posts.count)
        guard start < end else { return [] }
        return Array(MockData.posts[start..<end])
    }

    func fetchUserPosts(userId: String, page: Int, perPage: Int) async throws -> [Post] {
        try await simulateDelay()
        return MockData.posts.filter { $0.author.id == userId }
    }

    func fetchPost(id: String) async throws -> Post {
        try await simulateDelay(seconds: 0.3)
        guard let post = MockData.posts.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return post
    }

    func fetchExplorePosts(page: Int, perPage: Int) async throws -> [Post] {
        try await simulateDelay()
        return MockData.posts.shuffled()
    }

    func likePost(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
    }

    func unlikePost(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
    }

    func savePost(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
    }

    func unsavePost(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
    }

    // MARK: - Private

    private func simulateDelay(seconds: Double = 0.6) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
