//
//  FirebaseCommentDataSource.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation

// MARK: - FirebaseCommentDataSource

/// Skeletal actor for Firebase Comments.
/// Ready for rewriting logic from scratch.
actor FirebaseCommentDataSource {

    static let shared = FirebaseCommentDataSource()

    init() {}

    func fetchComments(postId: String, page: Int, perPage: Int) async throws -> [Comment] {
        _ = postId
        _ = page
        _ = perPage
        // TODO: Implement fetchComments logic from scratch
        return []
    }

    func addComment(postId: String, text: String, parentId: String?) async throws -> Comment {
        _ = postId
        _ = parentId
        // TODO: Implement addComment logic from scratch
        let myId = await SessionStore.shared.currentUserId
        let dummyUser = User(
            id: myId.isEmpty ? "user" : myId,
            username: "user",
            fullName: "User",
            email: nil,
            phone: nil,
            avatarURL: nil,
            bio: nil,
            website: nil,
            isVerified: false,
            isPrivate: false,
            followersCount: 0,
            followingCount: 0,
            postsCount: 0,
            createdAt: .now,
            isFollowing: false,
            isFollowedBy: false,
            isBlocked: false
        )
        return Comment(
            id: UUID().uuidString,
            postId: postId,
            author: dummyUser,
            text: text,
            likesCount: 0,
            isLiked: false,
            replies: [],
            parentId: parentId,
            createdAt: Date()
        )
    }

    func deleteComment(postId: String, commentId: String) async throws {
        _ = postId
        _ = commentId
        // TODO: Implement deleteComment logic from scratch
    }

    func likeComment(postId: String, commentId: String) async throws {
        _ = postId
        _ = commentId
        // TODO: Implement likeComment logic from scratch
    }

    func unlikeComment(postId: String, commentId: String) async throws {
        _ = postId
        _ = commentId
        // TODO: Implement unlikeComment logic from scratch
    }
}
