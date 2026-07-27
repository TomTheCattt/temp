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
        return MockData.currentUser
    }

    func fetchUser(id: String) async throws -> User {
        try await simulateDelay()
        if id == MockData.currentUser.id { return MockData.currentUser }
        guard let user = MockData.users.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return user
    }

    func searchUsers(query: String, page: Int, perPage: Int) async throws -> [User] {
        try await simulateDelay(seconds: 0.4)
        let lowered = query.lowercased()
        return MockData.users.filter {
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
