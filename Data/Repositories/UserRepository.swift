//
//  UserRepository.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - UserRepository

final class UserRepository: UserRepositoryProtocol, @unchecked Sendable {

    private let remoteDataSource: RemoteUserDataSource

    init(remoteDataSource: RemoteUserDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchCurrentUser() async throws -> User {
        try await remoteDataSource.fetchCurrentUser()
    }

    func fetchUser(id: String) async throws -> User {
        try await remoteDataSource.fetchUser(id: id)
    }

    func searchUsers(query: String, page: Int, perPage: Int) async throws -> [User] {
        try await remoteDataSource.searchUsers(query: query, page: page, perPage: perPage)
    }

    func updateProfileName(_ name: String) async throws -> User {
        try await remoteDataSource.updateProfileName(name)
    }

    func updateFullProfile(fullName: String?, bio: String?, website: String?, isPrivate: Bool?) async throws -> User {
        try await remoteDataSource.updateFullProfile(
            fullName: fullName,
            bio: bio,
            website: website,
            isPrivate: isPrivate
        )
    }

    func setPrivateAccount(_ isPrivate: Bool) async throws -> User {
        try await remoteDataSource.setPrivateAccount(isPrivate)
    }

    func updateAvatar(imageData: Data) async throws -> User {
        try await remoteDataSource.updateAvatar(imageData: imageData)
    }

    func follow(userId: String) async throws {
        try await remoteDataSource.follow(userId: userId)
    }

    func unfollow(userId: String) async throws {
        try await remoteDataSource.unfollow(userId: userId)
    }

    func block(userId: String) async throws {
        try await remoteDataSource.block(userId: userId)
    }

    func unblock(userId: String) async throws {
        try await remoteDataSource.unblock(userId: userId)
    }

    func fetchBlockedUsers(page: Int, perPage: Int) async throws -> [User] {
        try await remoteDataSource.fetchBlockedUsers(page: page, perPage: perPage)
    }

    func fetchSettings() async throws -> UserSettings {
        try await remoteDataSource.fetchSettings()
    }

    func updateSettings(_ patch: UserSettingsPatch) async throws -> UserSettings {
        try await remoteDataSource.updateSettings(patch)
    }

    func fetchCloseFriends(page: Int, perPage: Int) async throws -> [User] {
        try await remoteDataSource.fetchCloseFriends(page: page, perPage: perPage)
    }

    func setCloseFriends(userIds: [String]) async throws -> [User] {
        try await remoteDataSource.setCloseFriends(userIds: userIds)
    }

    func fetchFollowers(userId: String, page: Int, perPage: Int) async throws -> [User] {
        try await remoteDataSource.fetchFollowers(userId: userId, page: page, perPage: perPage)
    }

    func fetchFollowing(userId: String, page: Int, perPage: Int) async throws -> [User] {
        try await remoteDataSource.fetchFollowing(userId: userId, page: page, perPage: perPage)
    }

    func fetchSuggested(page: Int, perPage: Int) async throws -> [User] {
        try await remoteDataSource.fetchSuggested(page: page, perPage: perPage)
    }

    func fetchDeviceTokens() async throws -> [DeviceToken] {
        try await remoteDataSource.fetchDeviceTokens()
    }

    func addDeviceToken(token: String, platform: String) async throws {
        try await remoteDataSource.addDeviceToken(token: token, platform: platform)
    }

    func deleteDeviceToken(token: String) async throws {
        try await remoteDataSource.deleteDeviceToken(token: token)
    }
}
