//
//  FirebaseUserRepository.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation

// MARK: - FirebaseUserRepository

/// Production-ready Firebase implementation of `UserRepositoryProtocol`.
/// Delegates operations to `FirebaseUserDataSource` actor.
final class FirebaseUserRepository: UserRepositoryProtocol, @unchecked Sendable {

    private let dataSource: FirebaseUserDataSource

    init(dataSource: FirebaseUserDataSource = FirebaseUserDataSource.shared) {
        self.dataSource = dataSource
    }

    // MARK: - Profile

    func fetchCurrentUser() async throws -> User {
        try await dataSource.fetchCurrentUser()
    }

    func fetchUser(id: String) async throws -> User {
        try await dataSource.fetchUser(id: id)
    }

    func searchUsers(query: String, page: Int, perPage: Int) async throws -> [User] {
        try await dataSource.searchUsers(query: query, page: page, perPage: perPage)
    }

    func updateProfile(name: String?, bio: String?, website: String?) async throws -> User {
        try await dataSource.updateProfile(name: name, bio: bio, website: website)
    }

    func setPrivateAccount(_ isPrivate: Bool) async throws -> User {
        try await dataSource.setPrivateAccount(isPrivate)
    }

    func updateAvatar(imageData: Data) async throws -> User {
        try await dataSource.updateAvatar(imageData: imageData)
    }

    // MARK: - Follow / Block

    func follow(userId: String) async throws {
        try await dataSource.follow(userId: userId)
    }

    func unfollow(userId: String) async throws {
        try await dataSource.unfollow(userId: userId)
    }

    func block(userId: String) async throws {
        try await dataSource.block(userId: userId)
    }

    func unblock(userId: String) async throws {
        try await dataSource.unblock(userId: userId)
    }

    func fetchBlockedUsers(page: Int, perPage: Int) async throws -> [User] {
        try await dataSource.fetchBlockedUsers(page: page, perPage: perPage)
    }

    // MARK: - Settings

    func fetchSettings() async throws -> UserSettings {
        try await dataSource.fetchSettings()
    }

    func updateSettings(_ patch: UserSettingsPatch) async throws -> UserSettings {
        try await dataSource.updateSettings(patch)
    }

    // MARK: - Close Friends

    func fetchCloseFriends(page: Int, perPage: Int) async throws -> [User] {
        try await dataSource.fetchCloseFriends(page: page, perPage: perPage)
    }

    func setCloseFriends(userIds: [String]) async throws -> [User] {
        try await dataSource.setCloseFriends(userIds: userIds)
    }

    // MARK: - Lists

    func fetchFollowers(userId: String, page: Int, perPage: Int) async throws -> [User] {
        try await dataSource.fetchFollowers(userId: userId, page: page, perPage: perPage)
    }

    func fetchFollowing(userId: String, page: Int, perPage: Int) async throws -> [User] {
        try await dataSource.fetchFollowing(userId: userId, page: page, perPage: perPage)
    }

    func fetchSuggested(page: Int, perPage: Int) async throws -> [User] {
        try await dataSource.fetchSuggested(page: page, perPage: perPage)
    }
}
