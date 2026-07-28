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
    private let mockDataSource: MockUserDataSource

    init(
        remoteDataSource: RemoteUserDataSource,
        mockDataSource: MockUserDataSource = MockUserDataSource()
    ) {
        self.remoteDataSource = remoteDataSource
        self.mockDataSource = mockDataSource
    }

    func fetchCurrentUser() async throws -> User {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchCurrentUser()
        }
        return try await remoteDataSource.fetchCurrentUser()
    }

    func fetchUser(id: String) async throws -> User {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchUser(id: id)
        }
        return try await remoteDataSource.fetchUser(id: id)
    }

    func searchUsers(query: String, page: Int, perPage: Int) async throws -> [User] {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.searchUsers(query: query, page: page, perPage: perPage)
        }
        return try await remoteDataSource.searchUsers(query: query, page: page, perPage: perPage)
    }

    func updateProfile(name: String?, bio: String?, website: String?) async throws -> User {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.updateProfile(name: name, bio: bio, website: website)
        }
        return try await remoteDataSource.updateProfile(name: name, bio: bio, website: website)
    }

    func updateAvatar(imageData: Data) async throws -> User {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.updateAvatar(imageData: imageData)
        }
        return try await remoteDataSource.updateAvatar(imageData: imageData)
    }

    func follow(userId: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.follow(userId: userId)
        }
        try await remoteDataSource.follow(userId: userId)
    }

    func unfollow(userId: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.unfollow(userId: userId)
        }
        try await remoteDataSource.unfollow(userId: userId)
    }

    func block(userId: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.block(userId: userId)
        }
        try await remoteDataSource.block(userId: userId)
    }

    func unblock(userId: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.unblock(userId: userId)
        }
        try await remoteDataSource.unblock(userId: userId)
    }

    func fetchFollowers(userId: String, page: Int, perPage: Int) async throws -> [User] {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchFollowers(userId: userId, page: page, perPage: perPage)
        }
        return try await remoteDataSource.fetchFollowers(userId: userId, page: page, perPage: perPage)
    }

    func fetchFollowing(userId: String, page: Int, perPage: Int) async throws -> [User] {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchFollowing(userId: userId, page: page, perPage: perPage)
        }
        return try await remoteDataSource.fetchFollowing(userId: userId, page: page, perPage: perPage)
    }

    func fetchSuggested(page: Int, perPage: Int) async throws -> [User] {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchSuggested(page: page, perPage: perPage)
        }
        return try await remoteDataSource.fetchSuggested(page: page, perPage: perPage)
    }
}
