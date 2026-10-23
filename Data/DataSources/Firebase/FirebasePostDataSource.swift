//
//  FirebasePostDataSource.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation

// MARK: - FirebasePostDataSource

/// Skeletal actor for Firebase Posts and Feeds.
/// Ready for rewriting logic from scratch.
actor FirebasePostDataSource {

    static let shared = FirebasePostDataSource()

    init() {}

    func fetchFeed(page: Int, perPage: Int) async throws -> [Post] {
        _ = page
        _ = perPage
        // TODO: Implement fetchFeed logic from scratch
        return []
    }

    func fetchUserPosts(userId: String, page: Int, perPage: Int) async throws -> [Post] {
        _ = userId
        _ = page
        _ = perPage
        // TODO: Implement fetchUserPosts logic from scratch
        return []
    }

    func fetchPost(id: String) async throws -> Post {
        _ = id
        // TODO: Implement fetchPost logic from scratch
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
        return Post(
            id: id,
            author: dummyUser,
            caption: nil,
            mediaItems: [],
            location: nil,
            likesCount: 0,
            commentsCount: 0,
            createdAt: .now,
            isLiked: false,
            isSaved: false,
            isSponsored: false
        )
    }

    func createPost(caption: String?, mediaData: [Data], location: PostLocation?) async throws -> Post {
        _ = caption
        _ = mediaData
        _ = location
        // TODO: Implement createPost logic from scratch
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
        return Post(
            id: UUID().uuidString,
            author: dummyUser,
            caption: caption,
            mediaItems: [],
            location: location,
            likesCount: 0,
            commentsCount: 0,
            createdAt: .now,
            isLiked: false,
            isSaved: false,
            isSponsored: false
        )
    }

    func updatePost(id: String, caption: String?, location: PostLocation?) async throws -> Post {
        _ = id
        _ = caption
        _ = location
        // TODO: Implement updatePost logic from scratch
        return try await fetchPost(id: id)
    }

    func deletePost(id: String) async throws {
        _ = id
        // TODO: Implement deletePost logic from scratch
    }

    func likePost(id: String) async throws {
        _ = id
        // TODO: Implement likePost logic from scratch
    }

    func unlikePost(id: String) async throws {
        _ = id
        // TODO: Implement unlikePost logic from scratch
    }

    func savePost(id: String) async throws {
        _ = id
        // TODO: Implement savePost logic from scratch
    }

    func unsavePost(id: String) async throws {
        _ = id
        // TODO: Implement unsavePost logic from scratch
    }

    func fetchSavedPosts(page: Int, perPage: Int) async throws -> [Post] {
        _ = page
        _ = perPage
        // TODO: Implement fetchSavedPosts logic from scratch
        return []
    }

    func fetchExplorePosts(page: Int, perPage: Int) async throws -> [Post] {
        _ = page
        _ = perPage
        // TODO: Implement fetchExplorePosts logic from scratch
        return []
    }
}
