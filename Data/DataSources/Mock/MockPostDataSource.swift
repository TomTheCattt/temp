//
//  MockPostDataSource.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import os

// MARK: - MockPostStore

/// In-memory store so newly created, edited, liked, and deleted mock posts persist
/// across screens for the lifetime of the app session (mirrors backend persistence).
final class MockPostStore: @unchecked Sendable {

    static let shared = MockPostStore()

    private let lock = OSAllocatedUnfairLock()
    private var _posts: [Post] = MockData.posts

    private init() {}

    var posts: [Post] {
        get { lock.withLock { _posts } }
        set { lock.withLock { _posts = newValue } }
    }

    func insert(_ post: Post, at index: Int = 0) {
        lock.withLock {
            _posts.insert(post, at: index)
        }
    }

    func update(id: String, mutate: (inout Post) -> Void) -> Post? {
        lock.withLock {
            guard let idx = _posts.firstIndex(where: { $0.id == id }) else { return nil }
            mutate(&_posts[idx])
            return _posts[idx]
        }
    }

    func delete(id: String) {
        lock.withLock {
            _posts.removeAll { $0.id == id }
        }
    }

    @discardableResult
    func toggleLike(id: String, isLiked: Bool) -> Post? {
        update(id: id) { post in
            guard post.isLiked != isLiked else { return }
            post = post.withLike(isLiked)
        }
    }

    @discardableResult
    func toggleSave(id: String, isSaved: Bool) -> Post? {
        update(id: id) { post in
            post = post.withSaved(isSaved)
        }
    }

    @discardableResult
    func adjustCommentsCount(id: String, delta: Int) -> Post? {
        update(id: id) { post in
            post = Post(
                id: post.id,
                author: post.author,
                caption: post.caption,
                mediaItems: post.mediaItems,
                location: post.location,
                likesCount: post.likesCount,
                commentsCount: max(0, post.commentsCount + delta),
                createdAt: post.createdAt,
                isLiked: post.isLiked,
                isSaved: post.isSaved,
                isSponsored: post.isSponsored
            )
        }
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
        let userPosts = isCurrent
            ? allPosts.filter { $0.author.id == "user_current" || $0.author.id == currentUserId }
            : allPosts.filter { $0.author.id == userId }
        let start = (page - 1) * perPage
        let end = min(start + perPage, userPosts.count)
        guard start < end else { return [] }
        return Array(userPosts[start..<end])
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
        MockUserStore.shared.incrementPostsCount()
        return newPost
    }

    func fetchExplorePosts(page: Int, perPage: Int) async throws -> [Post] {
        try await simulateDelay()
        let posts = store.posts
        let start: Int = {
            if page == 1 {
                return 0
            }
            if perPage == 20 {
                return 30 + (page - 2) * perPage
            }
            return (page - 1) * perPage
        }()
        let end = min(start + perPage, posts.count)
        guard start < end else { return [] }
        return Array(posts[start..<end])
    }

    func likePost(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
        _ = store.toggleLike(id: id, isLiked: true)
    }

    func unlikePost(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
        _ = store.toggleLike(id: id, isLiked: false)
    }

    func savePost(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
        _ = store.toggleSave(id: id, isSaved: true)
    }

    func unsavePost(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
        _ = store.toggleSave(id: id, isSaved: false)
    }

    // MARK: - Private

    private func simulateDelay(seconds: Double = 0.6) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
