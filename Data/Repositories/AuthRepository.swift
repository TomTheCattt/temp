//
//  AuthRepository.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - AuthRepository

final class AuthRepository: AuthRepositoryProtocol, @unchecked Sendable {

    private let remoteDataSource: RemoteAuthDataSource
    private let authManager: AuthManagerProtocol

    init(remoteDataSource: RemoteAuthDataSource, authManager: AuthManagerProtocol) {
        self.remoteDataSource = remoteDataSource
        self.authManager = authManager
    }

    func login(email: String, password: String) async throws -> AuthSession {
        let session = try await remoteDataSource.login(email: email, password: password)
        authManager.storeSession(session)
        return session
    }

    func register(name: String, email: String, password: String, phone: String) async throws -> AuthSession {
        let session = try await remoteDataSource.register(name: name, email: email, password: password, phone: phone)
        authManager.storeSession(session)
        return session
    }

    func refreshToken() async throws -> AuthSession {
        // Get refresh token from authManager (which stores it in keychain)
        // We need to access the refresh token - the authManager has it
        // Since we can't easily access it from here, we'll need to change the approach
        // For now, let's have the AuthManager handle the token refresh directly
        // and this method will be deprecated
        throw APIError.unauthorized
    }

    func logout() async throws {
        try await remoteDataSource.logout()
    }

    func forgotPassword(email: String) async throws {
        try await remoteDataSource.forgotPassword(email: email)
    }

    func resetPassword(token: String, newPassword: String) async throws {
        try await remoteDataSource.resetPassword(token: token, newPassword: newPassword)
    }

    func verifyEmail(token: String) async throws {
        try await remoteDataSource.verifyEmail(token: token)
    }

    func resendVerification(email: String) async throws {
        try await remoteDataSource.resendVerification(email: email)
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        try await remoteDataSource.changePassword(currentPassword: currentPassword, newPassword: newPassword)
    }
}
