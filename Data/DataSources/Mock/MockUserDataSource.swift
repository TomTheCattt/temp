//
//  MockUserDataSource.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - MockUserDataSource

final class MockUserDataSource: Sendable {

    func fetchCurrentUser() async throws -> User {
        try await simulateDelay()
        return MockUserStore.shared.currentUser
    }

    func fetchUser(id: String) async throws -> User {
        try await simulateDelay()
        if id == MockUserStore.shared.currentUser.id { return MockUserStore.shared.currentUser }
        guard let user = MockData.users.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return user
    }

    func searchUsers(query: String, page: Int, perPage: Int) async throws -> [User] {
        try await simulateDelay(seconds: 0.4)
        let lowered = query.lowercased()
        var allCandidates = MockData.users
        let currentUser = MockUserStore.shared.currentUser
        if !allCandidates.contains(where: { $0.id == currentUser.id }) {
            allCandidates.insert(currentUser, at: 0)
        }
        return allCandidates.filter {
            $0.username.lowercased().contains(lowered) ||
            $0.fullName.lowercased().contains(lowered)
        }
    }

    func follow(userId: String) async throws {
        try await simulateDelay(seconds: 0.3)
    }

    func unfollow(userId: String) async throws {
        try await simulateDelay(seconds: 0.3)
    }

    func block(userId: String) async throws {
        try await simulateDelay(seconds: 0.3)
    }

    func unblock(userId: String) async throws {
        try await simulateDelay(seconds: 0.3)
    }

    func fetchBlockedUsers(page: Int, perPage: Int) async throws -> [User] {
        try await simulateDelay()
        return Array(MockData.users.prefix(2))
    }

    func fetchSettings() async throws -> UserSettings {
        try await simulateDelay(seconds: 0.3)
        return MockSettingsStore.shared.settings
    }

    func updateSettings(_ patch: UserSettingsPatch) async throws -> UserSettings {
        try await simulateDelay(seconds: 0.3)
        return MockSettingsStore.shared.apply(patch)
    }

    func fetchCloseFriends(page: Int, perPage: Int) async throws -> [User] {
        try await simulateDelay(seconds: 0.3)
        let ids = MockSettingsStore.shared.closeFriendIds
        return MockData.users.filter { ids.contains($0.id) }
    }

    func setCloseFriends(userIds: [String]) async throws -> [User] {
        try await simulateDelay(seconds: 0.3)
        MockSettingsStore.shared.closeFriendIds = Set(userIds)
        return MockData.users.filter { userIds.contains($0.id) }
    }

    func updateProfile(name: String?, bio: String?, website: String?) async throws -> User {
        try await simulateDelay(seconds: 0.5)
        return MockUserStore.shared.updateProfile(name: name, bio: bio, website: website)
    }

    func setPrivateAccount(_ isPrivate: Bool) async throws -> User {
        try await simulateDelay(seconds: 0.3)
        return MockUserStore.shared.setPrivateAccount(isPrivate)
    }

    func updateAvatar(imageData: Data) async throws -> User {
        try await simulateDelay(seconds: 0.8)
        return MockUserStore.shared.updateAvatar(imageData: imageData)
    }

    func fetchFollowers(userId: String, page: Int, perPage: Int) async throws -> [User] {
        try await simulateDelay()
        return Array(MockData.users.prefix(3))
    }

    func fetchFollowing(userId: String, page: Int, perPage: Int) async throws -> [User] {
        try await simulateDelay()
        return Array(MockData.users.suffix(3))
    }

    func fetchSuggested(page: Int, perPage: Int) async throws -> [User] {
        try await simulateDelay()
        return MockData.users.filter { !$0.isFollowing }
    }

    // MARK: - Private

    private func simulateDelay(seconds: Double = 0.5) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

// MARK: - MockUserStore

/// In-memory store so mock user profile updates persist for the lifetime
/// of the app session (mirrors backend persistence).
final class MockUserStore: @unchecked Sendable {

    static let shared = MockUserStore()

    private let lock = NSLock()
    private var _currentUser: User = MockData.currentUser

    private init() {}

    var currentUser: User {
        get { lock.lock(); defer { lock.unlock() }; return _currentUser }
        set { lock.lock(); _currentUser = newValue; lock.unlock() }
    }

    func updateProfile(name: String?, bio: String?, website: String?) -> User {
        lock.lock(); defer { lock.unlock() }
        _currentUser = User(
            id: _currentUser.id,
            username: _currentUser.username,
            fullName: name ?? _currentUser.fullName,
            email: _currentUser.email,
            phone: _currentUser.phone,
            avatarURL: _currentUser.avatarURL,
            bio: bio,
            website: website,
            isVerified: _currentUser.isVerified,
            isPrivate: _currentUser.isPrivate,
            followersCount: _currentUser.followersCount,
            followingCount: _currentUser.followingCount,
            postsCount: _currentUser.postsCount,
            createdAt: _currentUser.createdAt,
            isFollowing: _currentUser.isFollowing,
            isFollowedBy: _currentUser.isFollowedBy,
            isBlocked: _currentUser.isBlocked
        )
        return _currentUser
    }

    func updateAvatar(imageData: Data) -> User {
        lock.lock(); defer { lock.unlock() }
        let newURL: URL?
        if imageData.isEmpty {
            newURL = nil
        } else {
            newURL = URL(string: "https://i.pravatar.cc/300?u=\(_currentUser.username)&t=\(Int(Date().timeIntervalSince1970))")
        }
        _currentUser = User(
            id: _currentUser.id,
            username: _currentUser.username,
            fullName: _currentUser.fullName,
            email: _currentUser.email,
            phone: _currentUser.phone,
            avatarURL: newURL,
            bio: _currentUser.bio,
            website: _currentUser.website,
            isVerified: _currentUser.isVerified,
            isPrivate: _currentUser.isPrivate,
            followersCount: _currentUser.followersCount,
            followingCount: _currentUser.followingCount,
            postsCount: _currentUser.postsCount,
            createdAt: _currentUser.createdAt,
            isFollowing: _currentUser.isFollowing,
            isFollowedBy: _currentUser.isFollowedBy,
            isBlocked: _currentUser.isBlocked
        )
        return _currentUser
    }

    func setPrivateAccount(_ isPrivate: Bool) -> User {
        lock.lock(); defer { lock.unlock() }
        _currentUser = User(
            id: _currentUser.id,
            username: _currentUser.username,
            fullName: _currentUser.fullName,
            email: _currentUser.email,
            phone: _currentUser.phone,
            avatarURL: _currentUser.avatarURL,
            bio: _currentUser.bio,
            website: _currentUser.website,
            isVerified: _currentUser.isVerified,
            isPrivate: isPrivate,
            followersCount: _currentUser.followersCount,
            followingCount: _currentUser.followingCount,
            postsCount: _currentUser.postsCount,
            createdAt: _currentUser.createdAt,
            isFollowing: _currentUser.isFollowing,
            isFollowedBy: _currentUser.isFollowedBy,
            isBlocked: _currentUser.isBlocked
        )
        return _currentUser
    }
}

// MARK: - MockSettingsStore

/// In-memory store so mock settings & close-friends selections persist for the
/// lifetime of the app session (mirrors what the backend would remember).
final class MockSettingsStore: @unchecked Sendable {

    static let shared = MockSettingsStore()

    private let lock = NSLock()
    private var _settings = UserSettings.default
    private var _closeFriendIds = Set<String>()

    private init() {}

    var settings: UserSettings {
        lock.lock(); defer { lock.unlock() }
        return _settings
    }

    var closeFriendIds: Set<String> {
        get { lock.lock(); defer { lock.unlock() }; return _closeFriendIds }
        set { lock.lock(); _closeFriendIds = newValue; lock.unlock() }
    }

    func apply(_ patch: UserSettingsPatch) -> UserSettings {
        lock.lock(); defer { lock.unlock() }
        if let v = patch.pushEnabled { _settings.pushEnabled = v }
        if let v = patch.likeNotifications { _settings.likeNotifications = v }
        if let v = patch.commentNotifications { _settings.commentNotifications = v }
        if let v = patch.followNotifications { _settings.followNotifications = v }
        if let v = patch.directMessageNotifications { _settings.directMessageNotifications = v }
        if let v = patch.activityStatusVisible { _settings.activityStatusVisible = v }
        if let v = patch.highQualityUploads { _settings.highQualityUploads = v }
        if let v = patch.cellularDataEnabled { _settings.cellularDataEnabled = v }
        return _settings
    }
}
