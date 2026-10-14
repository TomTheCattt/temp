//
//  MockPostDataSource.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - MockPostDataSource

final class MockPostDataSource: @unchecked Sendable {

    private var posts: [Post] = MockData.posts
    private let lock = NSLock()

    func fetchFeed(page: Int, perPage: Int) async throws -> [Post] {
        try await simulateDelay()
        lock.lock()
        defer { lock.unlock() }
        let start = (page - 1) * perPage
        let end = min(start + perPage, posts.count)
        guard start < end else { return [] }
        return Array(posts[start..<end])
    }

    func fetchUserPosts(userId: String, page: Int, perPage: Int) async throws -> [Post] {
        try await simulateDelay()
        lock.lock()
        defer { lock.unlock() }
        return posts.filter { $0.author.id == userId }
    }

    func fetchPost(id: String) async throws -> Post {
        try await simulateDelay(seconds: 0.3)
        lock.lock()
        defer { lock.unlock() }
        guard let post = posts.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return post
    }

    func createPost(caption: String?, mediaData: [Data], location: PostLocation?) async throws -> Post {
        try await simulateDelay(seconds: 0.8)
        lock.lock()
        defer { lock.unlock() }

        let currentUser = SessionStore.shared.currentUser ?? MockData.currentUser
        let mediaItems: [MediaItem] = mediaData.isEmpty
            ? [
                MediaItem(
                    id: "media_\(UUID().uuidString.prefix(8))",
                    url: URL(string: "https://picsum.photos/seed/\(UUID().uuidString.prefix(6))/1080/1080")!,
                    thumbnailURL: nil,
                    type: .image,
                    width: 1080,
                    height: 1080,
                    duration: nil
                )
            ]
            : mediaData.enumerated().map { index, _ in
                MediaItem(
                    id: "media_\(UUID().uuidString.prefix(8))_\(index)",
                    url: URL(string: "https://picsum.photos/seed/\(UUID().uuidString.prefix(6))_\(index)/1080/1080")!,
                    thumbnailURL: nil,
                    type: .image,
                    width: 1080,
                    height: 1080,
                    duration: nil
                )
            }

        let newPost = Post(
            id: "post_new_\(UUID().uuidString.prefix(8))",
            author: currentUser,
            caption: caption,
            mediaItems: mediaItems,
            location: location,
            likesCount: 0,
            commentsCount: 0,
            createdAt: .now,
            isLiked: false,
            isSaved: false,
            isSponsored: false
        )

        posts.insert(newPost, at: 0)
        return newPost
    }

    func fetchExplorePosts(page: Int, perPage: Int) async throws -> [Post] {
        try await simulateDelay()
        lock.lock()
        defer { lock.unlock() }
        return posts.shuffled()
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
