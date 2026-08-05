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

    init(remoteDataSource: RemoteAuthDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func login(email: String, password: String) async throws -> AuthSession {
        try await remoteDataSource.login(email: email, password: password)
    }

    func register(name: String, email: String, password: String, phone: String) async throws -> AuthSession {
        try await remoteDataSource.register(name: name, email: email, password: password, phone: phone)
    }

    func refreshToken() async throws -> AuthSession {
        let idToken = try await remoteDataSource.refreshToken()
        let currentUser = SessionStore.shared.currentUser ?? User.empty
        return AuthSession(
            accessToken: idToken,
            refreshToken: "",
            user: currentUser,
            expiresAt: nil
        )
    }

    func logout() async throws {
        try await remoteDataSource.logout()
    }

    func forgotPassword(phoneNumber: String) async throws {
        try await remoteDataSource.forgotPassword(phoneNumber: phoneNumber)
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
