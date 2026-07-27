//
//  MockAuthDataSource.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - MockAuthDataSource

/// Mock data source for authentication — simulates API with delay.
final class MockAuthDataSource: Sendable {

    func login(email: String, password: String) async throws -> AuthSession {
        try await simulateDelay()

        // Accept any valid-looking credentials in mock
        return AuthSession(
            accessToken: "mock_access_token_\(UUID().uuidString)",
            refreshToken: "mock_refresh_token_\(UUID().uuidString)",
            user: MockData.currentUser,
            expiresAt: Date(timeIntervalSinceNow: 3600)
        )
    }

    func register(name: String, email: String, password: String, phone: String) async throws -> AuthSession {
        try await simulateDelay()

        let newUser = User(
            id: "user_new_\(UUID().uuidString.prefix(8))",
            username: name.lowercased().replacingOccurrences(of: " ", with: "_"),
            fullName: name,
            email: email,
            phone: phone,
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

        return AuthSession(
            accessToken: "mock_access_token_\(UUID().uuidString)",
            refreshToken: "mock_refresh_token_\(UUID().uuidString)",
            user: newUser,
            expiresAt: Date(timeIntervalSinceNow: 3600)
        )
    }

    func refreshToken() async throws -> AuthSession {
        try await simulateDelay(seconds: 0.3)

        return AuthSession(
            accessToken: "mock_refreshed_token_\(UUID().uuidString)",
            refreshToken: "mock_refresh_token_\(UUID().uuidString)",
            user: MockData.currentUser,
            expiresAt: Date(timeIntervalSinceNow: 3600)
        )
    }

    func logout() async throws {
        try await simulateDelay(seconds: 0.2)
    }

    // MARK: - Private

    private func simulateDelay(seconds: Double = 0.8) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
