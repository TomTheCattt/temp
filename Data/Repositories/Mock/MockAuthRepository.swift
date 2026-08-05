//
//  MockAuthRepository.swift
//  Instagram
//
//  Created by Kiro on 5/8/26.
//

import Foundation

// MARK: - MockAuthRepository

/// Mock implementation of AuthRepositoryProtocol for UI testing with local data.
final class MockAuthRepository: AuthRepositoryProtocol, @unchecked Sendable {

    private let dataSource = MockAuthDataSource()

    func login(email: String, password: String) async throws -> AuthSession {
        try await dataSource.login(email: email, password: password)
    }

    func register(name: String, email: String, password: String, phone: String) async throws -> AuthSession {
        try await dataSource.register(name: name, email: email, password: password, phone: phone)
    }

    func refreshToken() async throws -> AuthSession {
        try await dataSource.refreshToken()
    }

    func logout() async throws {
        try await dataSource.logout()
    }

    func forgotPassword(phoneNumber: String) async throws {
        // Mock: no-op with delay
        try await Task.sleep(nanoseconds: 500_000_000)
    }

    func resetPassword(token: String, newPassword: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }

    func verifyEmail(token: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }

    func resendVerification(email: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}
