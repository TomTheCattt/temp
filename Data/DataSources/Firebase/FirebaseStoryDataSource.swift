//
//  FirebaseStoryDataSource.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation

// MARK: - FirebaseStoryDataSource

/// Skeletal actor for Firebase Stories.
/// Ready for rewriting logic from scratch.
actor FirebaseStoryDataSource {

    static let shared = FirebaseStoryDataSource()

    init() {}

    func fetchStories() async throws -> [Story] {
        // TODO: Implement fetchStories logic from scratch
        return []
    }

    func fetchStoryItems(userId: String) async throws -> [StoryItem] {
        _ = userId
        // TODO: Implement fetchStoryItems logic from scratch
        return []
    }

    func createStory(mediaData: Data, type: StoryItem.MediaType, duration: TimeInterval) async throws -> Story {
        _ = mediaData
        _ = type
        _ = duration
        // TODO: Implement createStory logic from scratch
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
        return Story(
            id: UUID().uuidString,
            author: dummyUser,
            items: [],
            isViewed: false,
            createdAt: .now,
            expiresAt: .now.addingTimeInterval(86400)
        )
    }

    func markViewed(storyId: String) async throws {
        _ = storyId
        // TODO: Implement markViewed logic from scratch
    }

    func deleteStory(id: String) async throws {
        _ = id
        // TODO: Implement deleteStory logic from scratch
    }
}
