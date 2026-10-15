//
//  MockUserDataSource.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - MockUserDataSource

final class MockUserDataSource: Sendable {

    private var store: MockUserStore { MockUserStore.shared }

    func fetchCurrentUser() async throws -> User {
        try await simulateDelay()
        return SessionStore.shared.currentUser ?? store.currentUser
    }

    func fetchUser(id: String) async throws -> User {
        try await simulateDelay()
        let current = SessionStore.shared.currentUser ?? store.currentUser
        if id == current.id || id == "user_current" {
            return current
        }
        guard let user = store.user(id: id) else {
            throw APIError.notFound
        }
        return user
    }

    func searchUsers(query: String, page: Int, perPage: Int) async throws -> [User] {
        try await simulateDelay(seconds: 0.3)
        let lowered = query.lowercased()
        var allCandidates = store.allUsers
        let currentUser = store.currentUser
        if !allCandidates.contains(where: { $0.id == currentUser.id }) {
            allCandidates.insert(currentUser, at: 0)
        }
        let filtered = allCandidates.filter {
            $0.username.lowercased().contains(lowered) ||
            $0.fullName.lowercased().contains(lowered)
        }
        let start = (page - 1) * perPage
        let end = min(start + perPage, filtered.count)
        guard start < end else { return [] }
        return Array(filtered[start..<end])
    }

    func follow(userId: String) async throws {
        try await simulateDelay(seconds: 0.2)
        store.toggleFollow(userId: userId, isFollowing: true)
    }

    func unfollow(userId: String) async throws {
        try await simulateDelay(seconds: 0.2)
        store.toggleFollow(userId: userId, isFollowing: false)
    }

    func block(userId: String) async throws {
        try await simulateDelay(seconds: 0.2)
        store.toggleBlock(userId: userId, isBlocked: true)
    }

    func unblock(userId: String) async throws {
        try await simulateDelay(seconds: 0.2)
        store.toggleBlock(userId: userId, isBlocked: false)
    }

    func fetchBlockedUsers(page: Int, perPage: Int) async throws -> [User] {
        try await simulateDelay()
        let blocked = store.blockedUsers
        let start = (page - 1) * perPage
        let end = min(start + perPage, blocked.count)
        guard start < end else { return [] }
        return Array(blocked[start..<end])
    }

    func fetchSettings() async throws -> UserSettings {
        try await simulateDelay(seconds: 0.2)
        return MockSettingsStore.shared.settings
    }

    func updateSettings(_ patch: UserSettingsPatch) async throws -> UserSettings {
        try await simulateDelay(seconds: 0.2)
        return MockSettingsStore.shared.apply(patch)
    }

    func fetchCloseFriends(page: Int, perPage: Int) async throws -> [User] {
        try await simulateDelay(seconds: 0.2)
        let ids = MockSettingsStore.shared.closeFriendIds
        return store.allUsers.filter { ids.contains($0.id) }
    }

    func setCloseFriends(userIds: [String]) async throws -> [User] {
        try await simulateDelay(seconds: 0.2)
        MockSettingsStore.shared.closeFriendIds = Set(userIds)
        return store.allUsers.filter { userIds.contains($0.id) }
    }

    func updateProfile(name: String?, bio: String?, website: String?) async throws -> User {
        try await simulateDelay(seconds: 0.4)
        return store.updateProfile(name: name, bio: bio, website: website)
    }

    func setPrivateAccount(_ isPrivate: Bool) async throws -> User {
        try await simulateDelay(seconds: 0.2)
        return store.setPrivateAccount(isPrivate)
    }

    func updateAvatar(imageData: Data) async throws -> User {
        try await simulateDelay(seconds: 0.5)
        return store.updateAvatar(imageData: imageData)
    }

    func fetchFollowers(userId: String, page: Int, perPage: Int) async throws -> [User] {
        try await simulateDelay()
        return store.followers(for: userId, page: page, perPage: perPage)
    }

    func fetchFollowing(userId: String, page: Int, perPage: Int) async throws -> [User] {
        try await simulateDelay()
        return store.following(for: userId, page: page, perPage: perPage)
    }

    func fetchSuggested(page: Int, perPage: Int) async throws -> [User] {
        try await simulateDelay()
        return store.suggested(page: page, perPage: perPage)
    }

    // MARK: - Private

    private func simulateDelay(seconds: Double = 0.4) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

// MARK: - MockUserStore

/// In-memory store so mock user profile updates, follows, and blocks persist
/// for the lifetime of the app session (mirrors backend persistence).
final class MockUserStore: @unchecked Sendable {

    static let shared = MockUserStore()

    private let lock = NSLock()
    private var _currentUser: User = MockData.currentUser
    private var _users: [User] = MockData.users

    private init() {}

    var currentUser: User {
        get { lock.lock(); defer { lock.unlock() }; return _currentUser }
        set { lock.lock(); _currentUser = newValue; lock.unlock() }
    }

    var allUsers: [User] {
        lock.lock(); defer { lock.unlock() }
        return _users
    }

    func user(id: String) -> User? {
        lock.lock(); defer { lock.unlock() }
        if id == _currentUser.id || id == "user_current" {
            return _currentUser
        }
        return _users.first(where: { $0.id == id })
    }

    func toggleFollow(userId: String, isFollowing: Bool) {
        lock.lock(); defer { lock.unlock() }
        guard let index = _users.firstIndex(where: { $0.id == userId }) else { return }
        let u = _users[index]
        guard u.isFollowing != isFollowing else { return }
        let delta = isFollowing ? 1 : -1
        _users[index] = User(
            id: u.id,
            username: u.username,
            fullName: u.fullName,
            email: u.email,
            phone: u.phone,
            avatarURL: u.avatarURL,
            bio: u.bio,
            website: u.website,
            isVerified: u.isVerified,
            isPrivate: u.isPrivate,
            followersCount: max(0, u.followersCount + delta),
            followingCount: u.followingCount,
            postsCount: u.postsCount,
            createdAt: u.createdAt,
            isFollowing: isFollowing,
            isFollowedBy: u.isFollowedBy,
            isBlocked: u.isBlocked
        )
        // Also update currentUser's followingCount
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
            isPrivate: _currentUser.isPrivate,
            followersCount: _currentUser.followersCount,
            followingCount: max(0, _currentUser.followingCount + delta),
            postsCount: _currentUser.postsCount,
            createdAt: _currentUser.createdAt,
            isFollowing: _currentUser.isFollowing,
            isFollowedBy: _currentUser.isFollowedBy,
            isBlocked: _currentUser.isBlocked
        )
    }

    func toggleBlock(userId: String, isBlocked: Bool) {
        lock.lock(); defer { lock.unlock() }
        guard let index = _users.firstIndex(where: { $0.id == userId }) else { return }
        let u = _users[index]
        _users[index] = User(
            id: u.id,
            username: u.username,
            fullName: u.fullName,
            email: u.email,
            phone: u.phone,
            avatarURL: u.avatarURL,
            bio: u.bio,
            website: u.website,
            isVerified: u.isVerified,
            isPrivate: u.isPrivate,
            followersCount: u.followersCount,
            followingCount: u.followingCount,
            postsCount: u.postsCount,
            createdAt: u.createdAt,
            isFollowing: isBlocked ? false : u.isFollowing,
            isFollowedBy: isBlocked ? false : u.isFollowedBy,
            isBlocked: isBlocked
        )
    }

    var blockedUsers: [User] {
        lock.lock(); defer { lock.unlock() }
        return _users.filter { $0.isBlocked }
    }

    func followers(for userId: String, page: Int, perPage: Int) -> [User] {
        lock.lock(); defer { lock.unlock() }
        let candidates = _users.filter { $0.isFollowedBy || $0.id != userId }
        let start = (page - 1) * perPage
        let end = min(start + perPage, candidates.count)
        guard start < end else { return [] }
        return Array(candidates[start..<end])
    }

    func following(for userId: String, page: Int, perPage: Int) -> [User] {
        lock.lock(); defer { lock.unlock() }
        let candidates = _users.filter { $0.isFollowing }
        let start = (page - 1) * perPage
        let end = min(start + perPage, candidates.count)
        guard start < end else { return [] }
        return Array(candidates[start..<end])
    }

    func suggested(page: Int, perPage: Int) -> [User] {
        lock.lock(); defer { lock.unlock() }
        let candidates = _users.filter { !$0.isFollowing && $0.id != _currentUser.id }
        let start = (page - 1) * perPage
        let end = min(start + perPage, candidates.count)
        guard start < end else { return [] }
        return Array(candidates[start..<end])
    }

    func incrementPostsCount() {
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
            isPrivate: _currentUser.isPrivate,
            followersCount: _currentUser.followersCount,
            followingCount: _currentUser.followingCount,
            postsCount: _currentUser.postsCount + 1,
            createdAt: _currentUser.createdAt,
            isFollowing: _currentUser.isFollowing,
            isFollowedBy: _currentUser.isFollowedBy,
            isBlocked: _currentUser.isBlocked
        )
    }

    func decrementPostsCount() {
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
            isPrivate: _currentUser.isPrivate,
            followersCount: _currentUser.followersCount,
            followingCount: _currentUser.followingCount,
            postsCount: max(0, _currentUser.postsCount - 1),
            createdAt: _currentUser.createdAt,
            isFollowing: _currentUser.isFollowing,
            isFollowedBy: _currentUser.isFollowedBy,
            isBlocked: _currentUser.isBlocked
        )
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
