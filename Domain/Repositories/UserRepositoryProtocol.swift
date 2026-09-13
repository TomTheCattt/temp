//
//  UserRepositoryProtocol.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - UserRepositoryProtocol

protocol UserRepositoryProtocol: Sendable {

    /// Fetch the current authenticated user's profile.
    func fetchCurrentUser() async throws -> User

    /// Fetch a user by ID.
    func fetchUser(id: String) async throws -> User

    /// Search users by query string.
    func searchUsers(query: String, page: Int, perPage: Int) async throws -> [User]

    /// Update the current user's profile.
    func updateProfile(name: String?, bio: String?, website: String?) async throws -> User

    /// Update the current user's private-account setting.
    func setPrivateAccount(_ isPrivate: Bool) async throws -> User

    /// Update the current user's avatar.
    func updateAvatar(imageData: Data) async throws -> User

    /// Follow a user.
    func follow(userId: String) async throws

    /// Unfollow a user.
    func unfollow(userId: String) async throws

    /// Block a user.
    func block(userId: String) async throws

    /// Unblock a user.
    func unblock(userId: String) async throws

    /// Fetch the list of accounts the current user has blocked.
    func fetchBlockedUsers(page: Int, perPage: Int) async throws -> [User]

    /// Fetch the current user's per-account settings (notifications + data usage).
    func fetchSettings() async throws -> UserSettings

    /// Update the current user's settings. Returns the full, updated settings.
    func updateSettings(_ patch: UserSettingsPatch) async throws -> UserSettings

    /// Fetch the current user's Close Friends list.
    func fetchCloseFriends(page: Int, perPage: Int) async throws -> [User]

    /// Replace the entire Close Friends list. Returns the updated list.
    func setCloseFriends(userIds: [String]) async throws -> [User]

    /// Fetch followers list.
    func fetchFollowers(userId: String, page: Int, perPage: Int) async throws -> [User]

    /// Fetch following list.
    func fetchFollowing(userId: String, page: Int, perPage: Int) async throws -> [User]

    /// Fetch suggested users.
    func fetchSuggested(page: Int, perPage: Int) async throws -> [User]
}
