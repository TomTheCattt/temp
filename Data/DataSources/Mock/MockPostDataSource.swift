//
//  MockPostDataSource.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - MockPostStore

/// In-memory store so newly created, edited, and deleted mock posts persist
/// across screens for the lifetime of the app session (mirrors backend persistence).
final class MockPostStore: @unchecked Sendable {

    static let shared = MockPostStore()

    private let lock = NSLock()
    private var _posts: [Post] = MockData.posts

    private init() {}

    var posts: [Post] {
        get { lock.lock(); defer { lock.unlock() }; return _posts }
        set { lock.lock(); _posts = newValue; lock.unlock() }
    }

    func insert(_ post: Post, at index: Int = 0) {
        lock.lock(); defer { lock.unlock() }
        _posts.insert(post, at: index)
    }

    func update(id: String, mutate: (inout Post) -> Void) -> Post? {
        lock.lock(); defer { lock.unlock() }
        guard let idx = _posts.firstIndex(where: { $0.id == id }) else { return nil }
        mutate(&_posts[idx])
        return _posts[idx]
    }

    func delete(id: String) {
        lock.lock(); defer { lock.unlock() }
        _posts.removeAll { $0.id == id }
    }
}

// MARK: - MockPostDataSource

final class MockPostDataSource: @unchecked Sendable {

    private var store: MockPostStore { MockPostStore.shared }

    func fetchFeed(page: Int, perPage: Int) async throws -> [Post] {
        try await simulateDelay()
        let posts = store.posts
        let start = (page - 1) * perPage
        let end = min(start + perPage, posts.count)
        guard start < end else { return [] }
        return Array(posts[start..<end])
    }

    func fetchUserPosts(userId: String, page: Int, perPage: Int) async throws -> [Post] {
        try await simulateDelay()
        let currentUserId = SessionStore.shared.currentUserId
        let isCurrent = (userId == currentUserId || userId == "user_current" || (currentUserId.isEmpty && userId == MockData.currentUser.id))
        let allPosts = store.posts
        if isCurrent {
            return allPosts.filter { $0.author.id == "user_current" || $0.author.id == currentUserId }
        }
        return allPosts.filter { $0.author.id == userId }
    }

    func fetchPost(id: String) async throws -> Post {
        try await simulateDelay(seconds: 0.3)
        guard let post = store.posts.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return post
    }

    func createPost(caption: String?, mediaData: [Data], location: PostLocation?) async throws -> Post {
        try await simulateDelay(seconds: 0.8)

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

        store.insert(newPost, at: 0)
        return newPost
    }

    func fetchExplorePosts(page: Int, perPage: Int) async throws -> [Post] {
        try await simulateDelay()
        return store.posts.shuffled()
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
