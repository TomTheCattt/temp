//
//  UserRepository.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - UserRepository

final class UserRepository: UserRepositoryProtocol, @unchecked Sendable {

    private let mockDataSource: MockUserDataSource

    init(mockDataSource: MockUserDataSource = MockUserDataSource()) {
        self.mockDataSource = mockDataSource
    }

    func fetchCurrentUser() async throws -> User {
        try await mockDataSource.fetchCurrentUser()
    }

    func fetchUser(id: String) async throws -> User {
        try await mockDataSource.fetchUser(id: id)
    }

    func searchUsers(query: String, page: Int, perPage: Int) async throws -> [User] {
        try await mockDataSource.searchUsers(query: query, page: page, perPage: perPage)
    }

    func updateProfile(name: String?, bio: String?, website: String?) async throws -> User {
        // Mock: return current user with updated fields
        try await Task.sleep(nanoseconds: 500_000_000)
        return MockData.currentUser
    }

    func updateAvatar(imageData: Data) async throws -> User {
        try await Task.sleep(nanoseconds: 800_000_000)
        return MockData.currentUser
    }

    func follow(userId: String) async throws {
        try await mockDataSource.follow(userId: userId)
    }

    func unfollow(userId: String) async throws {
        try await mockDataSource.unfollow(userId: userId)
    }

    func block(userId: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }

    func unblock(userId: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }

    func fetchFollowers(userId: String, page: Int, perPage: Int) async throws -> [User] {
        try await mockDataSource.fetchFollowers(userId: userId, page: page, perPage: perPage)
    }

    func fetchFollowing(userId: String, page: Int, perPage: Int) async throws -> [User] {
        try await mockDataSource.fetchFollowing(userId: userId, page: page, perPage: perPage)
    }

    func fetchSuggested(page: Int, perPage: Int) async throws -> [User] {
        try await mockDataSource.fetchSuggested(page: page, perPage: perPage)
    }
}
