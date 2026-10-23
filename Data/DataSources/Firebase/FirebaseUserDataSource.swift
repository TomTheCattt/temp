//
//  FirebaseUserDataSource.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation

// MARK: - FirebaseUserDataSource

/// Skeletal actor for Firebase Users, Profiles, and Settings.
/// Ready for rewriting logic from scratch.
actor FirebaseUserDataSource {

    static let shared = FirebaseUserDataSource()

    init() {}

    private func createDummyUser(id: String = "user_me", username: String = "user") -> User {
        User(
            id: id,
            username: username,
            fullName: username.capitalized,
            email: "\(username)@example.com",
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
    }

    func saveUser(_ user: User) async throws {
        _ = user
        // TODO: Implement saveUser logic from scratch
    }

    func updateUserCache(_ user: User) {
        _ = user
    }

    func fetchCurrentUser() async throws -> User {
        if let current = await SessionStore.shared.currentUser {
            return current
        }
        let myId = await SessionStore.shared.currentUserId
        return createDummyUser(id: myId)
    }

    func fetchUser(id: String) async throws -> User {
        // TODO: Implement fetchUser logic from scratch
        return createDummyUser(id: id)
    }

    func searchUsers(query: String, page: Int, perPage: Int) async throws -> [User] {
        _ = query
        _ = page
        _ = perPage
        // TODO: Implement searchUsers logic from scratch
        return []
    }

    func updateProfile(name: String?, bio: String?, website: String?) async throws -> User {
        _ = name
        _ = bio
        _ = website
        // TODO: Implement updateProfile logic from scratch
        return try await fetchCurrentUser()
    }

    func setPrivateAccount(_ isPrivate: Bool) async throws -> User {
        _ = isPrivate
        // TODO: Implement setPrivateAccount logic from scratch
        return try await fetchCurrentUser()
    }

    func updateAvatar(imageData: Data) async throws -> User {
        _ = imageData
        // TODO: Implement updateAvatar logic from scratch
        return try await fetchCurrentUser()
    }

    func follow(userId: String) async throws {
        _ = userId
        // TODO: Implement follow logic from scratch
    }

    func unfollow(userId: String) async throws {
        _ = userId
        // TODO: Implement unfollow logic from scratch
    }

    func block(userId: String) async throws {
        _ = userId
        // TODO: Implement block logic from scratch
    }

    func unblock(userId: String) async throws {
        _ = userId
        // TODO: Implement unblock logic from scratch
    }

    func fetchBlockedUsers(page: Int, perPage: Int) async throws -> [User] {
        _ = page
        _ = perPage
        // TODO: Implement fetchBlockedUsers logic from scratch
        return []
    }

    func fetchSettings() async throws -> UserSettings {
        // TODO: Implement fetchSettings logic from scratch
        return UserSettings(
            pushEnabled: true,
            likeNotifications: true,
            commentNotifications: true,
            followNotifications: true,
            directMessageNotifications: true,
            activityStatusVisible: true,
            highQualityUploads: true,
            cellularDataEnabled: true
        )
    }

    func updateSettings(_ patch: UserSettingsPatch) async throws -> UserSettings {
        _ = patch
        // TODO: Implement updateSettings logic from scratch
        return try await fetchSettings()
    }

    func fetchCloseFriends(page: Int, perPage: Int) async throws -> [User] {
        _ = page
        _ = perPage
        // TODO: Implement fetchCloseFriends logic from scratch
        return []
    }

    func setCloseFriends(userIds: [String]) async throws -> [User] {
        _ = userIds
        // TODO: Implement setCloseFriends logic from scratch
        return []
    }

    func fetchFollowers(userId: String, page: Int, perPage: Int) async throws -> [User] {
        _ = userId
        _ = page
        _ = perPage
        // TODO: Implement fetchFollowers logic from scratch
        return []
    }

    func fetchFollowing(userId: String, page: Int, perPage: Int) async throws -> [User] {
        _ = userId
        _ = page
        _ = perPage
        // TODO: Implement fetchFollowing logic from scratch
        return []
    }

    func fetchSuggested(page: Int, perPage: Int) async throws -> [User] {
        _ = page
        _ = perPage
        // TODO: Implement fetchSuggested logic from scratch
        return []
    }
}
