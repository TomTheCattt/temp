//
//  MockCommentDataSource.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - MockCommentStore

/// In-memory store for comments and replies so additions, deletions,
/// and like toggles persist across screen navigations.
final class MockCommentStore: @unchecked Sendable {

    static let shared = MockCommentStore()

    private let lock = NSLock()
    /// Maps postId -> list of top-level comments
    private var _commentsByPostId: [String: [Comment]] = [:]

    private init() {
        // Seed initial comments from MockData
        for comment in MockData.comments {
            var list = _commentsByPostId[comment.postId] ?? []
            list.append(comment)
            _commentsByPostId[comment.postId] = list
        }
    }

    func comments(forPostId postId: String) -> [Comment] {
        lock.lock(); defer { lock.unlock() }
        if let existing = _commentsByPostId[postId] {
            return existing
        }
        // If post exists in MockPostStore and has commentsCount > 0 but no seed comments, generate realistic initial comments
        if let post = MockPostStore.shared.posts.first(where: { $0.id == postId }), post.commentsCount > 0 {
            let count = min(post.commentsCount, 5)
            let generated = (0..<count).map { idx in
                Comment(
                    id: "comment_\(postId)_\(idx)",
                    postId: postId,
                    author: MockData.users[(idx + abs(postId.hashValue)) % MockData.users.count],
                    text: ["Super cool! 🔥", "Amazing perspective 📸", "So inspiring ✨", "Love this so much 😍", "Incredible work! 👏"][idx % 5],
                    likesCount: idx + 1,
                    isLiked: false,
                    replies: [],
                    parentId: nil,
                    createdAt: Date(timeIntervalSinceNow: -Double(idx + 1) * 3600)
                )
            }
            _commentsByPostId[postId] = generated
            return generated
        }
        return []
    }

    func replies(forCommentId commentId: String) -> [Comment] {
        lock.lock(); defer { lock.unlock() }
        for comments in _commentsByPostId.values {
            if let comment = comments.first(where: { $0.id == commentId }) {
                return comment.replies
            }
        }
        return []
    }

    func addComment(postId: String, author: User, text: String, parentId: String?) -> Comment {
        lock.lock(); defer { lock.unlock() }
        let newComment = Comment(
            id: "comment_\(UUID().uuidString.prefix(8))",
            postId: postId,
            author: author,
            text: text,
            likesCount: 0,
            isLiked: false,
            replies: [],
            parentId: parentId,
            createdAt: .now
        )

        var list = _commentsByPostId[postId] ?? []
        if let parentId = parentId {
            // Append to replies of parent comment
            if let parentIndex = list.firstIndex(where: { $0.id == parentId }) {
                var parent = list[parentIndex]
                parent = Comment(
                    id: parent.id,
                    postId: parent.postId,
                    author: parent.author,
                    text: parent.text,
                    likesCount: parent.likesCount,
                    isLiked: parent.isLiked,
                    replies: parent.replies + [newComment],
                    parentId: parent.parentId,
                    createdAt: parent.createdAt
                )
                list[parentIndex] = parent
            } else {
                list.append(newComment)
            }
        } else {
            list.insert(newComment, at: 0)
        }
        _commentsByPostId[postId] = list
        MockPostStore.shared.adjustCommentsCount(id: postId, delta: 1)
        return newComment
    }

    func deleteComment(id: String) {
        lock.lock(); defer { lock.unlock() }
        for (postId, var list) in _commentsByPostId {
            if let index = list.firstIndex(where: { $0.id == id }) {
                list.remove(at: index)
                _commentsByPostId[postId] = list
                MockPostStore.shared.adjustCommentsCount(id: postId, delta: -1)
                return
            }
            // Check replies
            for i in 0..<list.count {
                if let replyIndex = list[i].replies.firstIndex(where: { $0.id == id }) {
                    var replies = list[i].replies
                    replies.remove(at: replyIndex)
                    let parent = list[i]
                    list[i] = Comment(
                        id: parent.id,
                        postId: parent.postId,
                        author: parent.author,
                        text: parent.text,
                        likesCount: parent.likesCount,
                        isLiked: parent.isLiked,
                        replies: replies,
                        parentId: parent.parentId,
                        createdAt: parent.createdAt
                    )
                    _commentsByPostId[postId] = list
                    MockPostStore.shared.adjustCommentsCount(id: postId, delta: -1)
                    return
                }
            }
        }
    }

    func toggleLike(id: String, isLiked: Bool) {
        lock.lock(); defer { lock.unlock() }
        for (postId, var list) in _commentsByPostId {
            if let index = list.firstIndex(where: { $0.id == id }) {
                let c = list[index]
                let delta = isLiked ? 1 : -1
                list[index] = Comment(
                    id: c.id,
                    postId: c.postId,
                    author: c.author,
                    text: c.text,
                    likesCount: max(0, c.likesCount + delta),
                    isLiked: isLiked,
                    replies: c.replies,
                    parentId: c.parentId,
                    createdAt: c.createdAt
                )
                _commentsByPostId[postId] = list
                return
            }
            // Check replies
            for i in 0..<list.count {
                if let replyIndex = list[i].replies.firstIndex(where: { $0.id == id }) {
                    var replies = list[i].replies
                    let r = replies[replyIndex]
                    let delta = isLiked ? 1 : -1
                    replies[replyIndex] = Comment(
                        id: r.id,
                        postId: r.postId,
                        author: r.author,
                        text: r.text,
                        likesCount: max(0, r.likesCount + delta),
                        isLiked: isLiked,
                        replies: r.replies,
                        parentId: r.parentId,
                        createdAt: r.createdAt
                    )
                    let parent = list[i]
                    list[i] = Comment(
                        id: parent.id,
                        postId: parent.postId,
                        author: parent.author,
                        text: parent.text,
                        likesCount: parent.likesCount,
                        isLiked: parent.isLiked,
                        replies: replies,
                        parentId: parent.parentId,
                        createdAt: parent.createdAt
                    )
                    _commentsByPostId[postId] = list
                    return
                }
            }
        }
    }
}

// MARK: - MockCommentDataSource

final class MockCommentDataSource: @unchecked Sendable {

    private var store: MockCommentStore { MockCommentStore.shared }

    func fetchComments(postId: String, page: Int, perPage: Int) async throws -> [Comment] {
        try await simulateDelay()
        let all = store.comments(forPostId: postId)
        let start = (page - 1) * perPage
        let end = min(start + perPage, all.count)
        guard start < end else { return [] }
        return Array(all[start..<end])
    }

    func fetchReplies(commentId: String, page: Int, perPage: Int) async throws -> [Comment] {
        try await simulateDelay()
        let all = store.replies(forCommentId: commentId)
        let start = (page - 1) * perPage
        let end = min(start + perPage, all.count)
        guard start < end else { return [] }
        return Array(all[start..<end])
    }

    func addComment(postId: String, text: String, parentId: String?) async throws -> Comment {
        try await simulateDelay(seconds: 0.3)
        let currentUser = SessionStore.shared.currentUser ?? MockData.currentUser
        return store.addComment(postId: postId, author: currentUser, text: text, parentId: parentId)
    }

    func deleteComment(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
        store.deleteComment(id: id)
    }

    func likeComment(id: String) async throws {
        try await simulateDelay(seconds: 0.1)
        store.toggleLike(id: id, isLiked: true)
    }

    func unlikeComment(id: String) async throws {
        try await simulateDelay(seconds: 0.1)
        store.toggleLike(id: id, isLiked: false)
    }

    // MARK: - Private

    private func simulateDelay(seconds: Double = 0.4) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
