//
//  AuthRepository.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - AuthRepository

final class AuthRepository: AuthRepositoryProtocol, @unchecked Sendable {

    private let mockDataSource: MockAuthDataSource

    init(mockDataSource: MockAuthDataSource = MockAuthDataSource()) {
        self.mockDataSource = mockDataSource
    }

    func login(email: String, password: String) async throws -> AuthSession {
        try await mockDataSource.login(email: email, password: password)
    }

    func register(name: String, email: String, password: String, phone: String) async throws -> AuthSession {
        try await mockDataSource.register(name: name, email: email, password: password, phone: phone)
    }

    func refreshToken() async throws -> AuthSession {
        try await mockDataSource.refreshToken()
    }

    func logout() async throws {
        try await mockDataSource.logout()
    }

    func forgotPassword(phoneNumber: String) async throws {
        // Mock: just simulate delay
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
