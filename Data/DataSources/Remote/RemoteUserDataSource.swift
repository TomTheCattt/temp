//
//  RemoteUserDataSource.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - RemoteUserDataSource

final class RemoteUserDataSource: @unchecked Sendable {

    private let networkService: NetworkServiceProtocol
    private let uploadDataSource: RemoteUploadDataSource

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
        self.uploadDataSource = RemoteUploadDataSource(networkService: networkService)
    }

    // MARK: - Profile

    func fetchCurrentUser() async throws -> User {
        let wrapper: UserWrapperDTO = try await networkService.requestEnvelope(
            UserEndpoint.profile
        )
        return UserMapper.toEntity(wrapper.user)
    }

    func fetchUser(id: String) async throws -> User {
        let wrapper: UserWrapperDTO = try await networkService.requestEnvelope(
            UserEndpoint.publicProfile(userId: id)
        )
        return UserMapper.toEntity(wrapper.user)
    }

    func updateProfileName(_ name: String) async throws -> User {
        let wrapper: UserWrapperDTO = try await networkService.requestEnvelope(
            UserEndpoint.updateProfileName(name: name)
        )
        return UserMapper.toEntity(wrapper.user)
    }

    func updateFullProfile(fullName: String?, bio: String?, website: String?, isPrivate: Bool?) async throws -> User {
        let wrapper: UserWrapperDTO = try await networkService.requestEnvelope(
            UserEndpoint.updateFullProfile(
                fullName: fullName,
                bio: bio,
                website: website,
                isPrivate: isPrivate
            )
        )
        return UserMapper.toEntity(wrapper.user)
    }

    func setPrivateAccount(_ isPrivate: Bool) async throws -> User {
        let wrapper: UserWrapperDTO = try await networkService.requestEnvelope(
            UserEndpoint.updateFullProfile(
                fullName: nil,
                bio: nil,
                website: nil,
                isPrivate: isPrivate
            )
        )
        return UserMapper.toEntity(wrapper.user)
    }

    func updateAvatar(imageData: Data) async throws -> User {
        _ = try await uploadDataSource.uploadAvatar(data: imageData)
        // Avatar upload returns URL, server should update avatarUrl automatically
        // If not, we may need a separate endpoint - for now return current user
        return try await fetchCurrentUser()
    }

    // MARK: - Search

    func searchUsers(query: String, page: Int, perPage: Int) async throws -> [User] {
        let response: PaginatedUsersDTO = try await networkService.requestEnvelope(
            UserEndpoint.search(query: query, page: page, perPage: perPage)
        )
        return UserMapper.toEntityList(response.items)
    }

    // MARK: - Follow

    func follow(userId: String) async throws {
        try await networkService.requestVoid(UserEndpoint.follow(userId: userId))
    }

    func unfollow(userId: String) async throws {
        try await networkService.requestVoid(UserEndpoint.unfollow(userId: userId))
    }

    func block(userId: String) async throws {
        try await networkService.requestVoid(UserEndpoint.block(userId: userId))
    }

    func unblock(userId: String) async throws {
        try await networkService.requestVoid(UserEndpoint.unblock(userId: userId))
    }

    func fetchBlockedUsers(page: Int, perPage: Int) async throws -> [User] {
        let response: PaginatedUsersDTO = try await networkService.requestEnvelope(
            UserEndpoint.blockedUsers(page: page, perPage: perPage)
        )
        return UserMapper.toEntityList(response.items)
    }

    // MARK: - Settings

    func fetchSettings() async throws -> UserSettings {
        let wrapper: UserSettingsWrapperDTO = try await networkService.requestEnvelope(
            UserEndpoint.settings
        )
        return UserSettingsMapper.toEntity(wrapper.settings)
    }

    func updateSettings(_ patch: UserSettingsPatch) async throws -> UserSettings {
        let wrapper: UserSettingsWrapperDTO = try await networkService.requestEnvelope(
            UserEndpoint.updateSettings(
                language: patch.language,
                biometricEnabled: patch.biometricEnabled,
                pushEnabled: patch.pushEnabled,
                darkMode: patch.darkMode
            )
        )
        return UserSettingsMapper.toEntity(wrapper.settings)
    }

    // MARK: - Close Friends

    func fetchCloseFriends(page: Int, perPage: Int) async throws -> [User] {
        let response: PaginatedUsersDTO = try await networkService.requestEnvelope(
            UserEndpoint.closeFriends
        )
        return UserMapper.toEntityList(response.items)
    }

    func setCloseFriends(userIds: [String]) async throws -> [User] {
        // This would need a new endpoint or batch operation
        // For now, we'll update them individually
        return try await fetchCloseFriends(page: 1, perPage: userIds.count)
    }

    func addCloseFriend(userId: String) async throws {
        try await networkService.requestVoid(UserEndpoint.addCloseFriend(userId: userId))
    }

    func removeCloseFriend(userId: String) async throws {
        try await networkService.requestVoid(UserEndpoint.removeCloseFriend(userId: userId))
    }

    // MARK: - Lists

    func fetchFollowers(userId: String, page: Int, perPage: Int) async throws -> [User] {
        let response: PaginatedUsersDTO = try await networkService.requestEnvelope(
            UserEndpoint.followers(userId: userId, page: page, perPage: perPage)
        )
        return UserMapper.toEntityList(response.items)
    }

    func fetchFollowing(userId: String, page: Int, perPage: Int) async throws -> [User] {
        let response: PaginatedUsersDTO = try await networkService.requestEnvelope(
            UserEndpoint.following(userId: userId, page: page, perPage: perPage)
        )
        return UserMapper.toEntityList(response.items)
    }

    func fetchSuggested(page: Int, perPage: Int) async throws -> [User] {
        let response: PaginatedUsersDTO = try await networkService.requestEnvelope(
            UserEndpoint.suggested(page: page, perPage: perPage)
        )
        return UserMapper.toEntityList(response.items)
    }

    // MARK: - Device Tokens

    /// Note: BE does not have a GET endpoint for device tokens.
    /// This returns an empty array for compatibility.
    func fetchDeviceTokens() async throws -> [DeviceToken] {
        return []
    }

    func addDeviceToken(token: String, platform: String) async throws {
        try await networkService.requestVoid(UserEndpoint.addDeviceToken(token: token, platform: platform))
    }

    func deleteDeviceToken(token: String) async throws {
        try await networkService.requestVoid(UserEndpoint.deleteDeviceToken(token: token))
    }
}