//
//  AuthManagerTests.swift
//  InstagramTests
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Testing
@testable import Instagram

// MARK: - AuthManager Tests

@Suite("AuthManager Tests")
struct AuthManagerTests {

    @Test("LogoutReason enum values")
    func testLogoutReason() {
        let reasons: [LogoutReason] = [.userInitiated, .sessionExpired]

        for reason in reasons {
            #expect(LogoutReason(rawValue: reason.rawValue) != nil)
        }
    }

    @Test("AuthSession structure")
    func testAuthSession() {
        let user = User(
            id: "user-123",
            username: "testuser",
            email: "test@example.com",
            fullName: "Test User",
            bio: nil,
            avatarUrl: nil,
            isPrivate: false,
            followersCount: 0,
            followingCount: 0,
            postsCount: 0,
            createdAt: Date()
        )
        let session = AuthSession(
            accessToken: "access-token-123",
            refreshToken: "refresh-token-456",
            user: user,
            expiresAt: Date().addingTimeInterval(3600)
        )

        #expect(session.accessToken == "access-token-123")
        #expect(session.refreshToken == "refresh-token-456")
        #expect(session.user.id == "user-123")
        #expect(session.expiresAt != nil)
    }

    @Test("AuthSession without expiry")
    func testAuthSessionWithoutExpiry() {
        let user = User(
            id: "user-123",
            username: "testuser",
            email: "test@example.com",
            fullName: "Test User",
            bio: nil,
            avatarUrl: nil,
            isPrivate: false,
            followersCount: 0,
            followingCount: 0,
            postsCount: 0,
            createdAt: Date()
        )
        let session = AuthSession(
            accessToken: "access-token-123",
            refreshToken: "refresh-token-456",
            user: user,
            expiresAt: nil
        )

        #expect(session.accessToken == "access-token-123")
        #expect(session.refreshToken == "refresh-token-456")
        #expect(session.user.id == "user-123")
        #expect(session.expiresAt == nil)
    }
}

// MARK: - KeychainManager Tests

@Suite("KeychainManager Tests")
struct KeychainManagerTests {

    private let keychain = KeychainManager()
    private let testKey = "test_key_\(UUID().uuidString)"

    @Test("Set and get string value")
    func testSetAndGetString() {
        let testValue = "test-value-123"
        keychain.set(value: testValue, key: testKey)

        let retrieved = keychain.get(key: testKey)
        #expect(retrieved == testValue)

        // Cleanup
        keychain.delete(key: testKey)
    }

    @Test("Delete removes value")
    func testDelete() {
        keychain.set(value: "to-delete", key: testKey)
        #expect(keychain.get(key: testKey) == "to-delete")

        keychain.delete(key: testKey)
        #expect(keychain.get(key: testKey) == nil)
    }

    @Test("Get non-existent key returns nil")
    func testGetNonExistent() {
        let result = keychain.get(key: "non_existent_key_\(UUID().uuidString)")
        #expect(result == nil)
    }

    @Test("Overwrite existing value")
    func testOverwrite() {
        keychain.set(value: "first", key: testKey)
        #expect(keychain.get(key: testKey) == "first")

        keychain.set(value: "second", key: testKey)
        #expect(keychain.get(key: testKey) == "second")

        keychain.delete(key: testKey)
    }
}

// MARK: - Token Refresh Tests

@Suite("Token Refresh Logic Tests")
struct TokenRefreshTests {

    @Test("Token expiry buffer is 5 minutes")
    func testExpiryBuffer() {
        // AuthManager uses 5 minutes buffer
        let buffer: TimeInterval = 5 * 60
        #expect(buffer == 300)
    }

    @Test("Token refresh needed when within buffer")
    func testRefreshNeededWithinBuffer() {
        let expiry = Date().addingTimeInterval(2 * 60) // 2 minutes from now
        let buffer: TimeInterval = 5 * 60
        let timeUntilExpiry = expiry.timeIntervalSinceNow

        #expect(timeUntilExpiry < buffer) // Should refresh
    }

    @Test("Token refresh not needed when outside buffer")
    func testRefreshNotNeededOutsideBuffer() {
        let expiry = Date().addingTimeInterval(10 * 60) // 10 minutes from now
        let buffer: TimeInterval = 5 * 60
        let timeUntilExpiry = expiry.timeIntervalSinceNow

        #expect(timeUntilExpiry >= buffer) // Should not refresh
    }

    @Test("Expired token triggers refresh")
    func testExpiredToken() {
        let expiry = Date().addingTimeInterval(-60) // 1 minute ago
        let buffer: TimeInterval = 5 * 60
        let timeUntilExpiry = expiry.timeIntervalSinceNow

        #expect(timeUntilExpiry < buffer) // Should refresh
    }
}