//
//  RemoteAuthDataSource.swift
//  Instagram
//
//  Created by Kiro on 1/8/26.
//

import Foundation

// MARK: - RemoteAuthDataSource

/// Handles authentication flow with Better Auth backend:
/// 1. Direct email/password authentication (no Firebase)
/// 2. Backend issues its own access/refresh tokens (JWT)
final class RemoteAuthDataSource: @unchecked Sendable {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    // MARK: - Login

    /// Sign in with email/password via Better Auth backend.
    func login(email: String, password: String) async throws -> AuthSession {
        let dto: AuthResponseDTO = try await networkService.requestEnvelope(
            AuthEndpoint.login(email: email, password: password)
        )

        return dto.toAuthSession()
    }

    // MARK: - Register

    /// Create account with email/password via Better Auth backend.
    func register(name: String, email: String, password: String, phone: String?) async throws -> AuthSession {
        let dto: AuthResponseDTO = try await networkService.requestEnvelope(
            AuthEndpoint.register(email: email, password: password, username: name, fullName: name, phone: phone)
        )

        return dto.toAuthSession()
    }

    // MARK: - Refresh Token

    /// Get a fresh access token from the backend using the refresh token.
    func refreshToken() async throws -> String {
        let dto: RefreshTokenDTO = try await networkService.requestEnvelope(
            AuthEndpoint.refresh
        )
        return dto.accessToken
    }

    /// Get a fresh access token with expiry info.
    func refreshTokenWithExpiry() async throws -> (token: String, expiresAt: Date?) {
        let dto: RefreshTokenDTO = try await networkService.requestEnvelope(
            AuthEndpoint.refresh
        )
        let expiresAt = dto.expiresAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        return (dto.accessToken, expiresAt)
    }

    // MARK: - Logout

    func logout() async throws {
        try await networkService.requestVoid(AuthEndpoint.logout)
    }

    func logoutAllDevices() async throws {
        try await networkService.requestVoid(AuthEndpoint.logoutAllDevices)
    }

    // MARK: - Password & Email

    func forgotPassword(email: String) async throws {
        try await networkService.requestVoid(AuthEndpoint.forgotPassword(email: email))
    }

    func resetPassword(token: String, newPassword: String) async throws {
        // Note: Backend uses verify-email + change-password flow
        // This is kept for compatibility but may not be used
        try await networkService.requestVoid(AuthEndpoint.verifyEmail(token: token))
    }

    func verifyEmail(token: String) async throws {
        try await networkService.requestVoid(AuthEndpoint.verifyEmail(token: token))
    }

    func resendVerification(email: String) async throws {
        try await networkService.requestVoid(AuthEndpoint.resendVerification(email: email))
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        try await networkService.requestVoid(AuthEndpoint.changePassword(currentPassword: currentPassword, newPassword: newPassword))
    }

    // MARK: - Get Current User

    func getCurrentUser() async throws -> UserDTO {
        let dto: UserDTO = try await networkService.requestEnvelope(AuthEndpoint.me)
        return dto
    }
}

// MARK: - DTOs

/// DTO for auth API responses (login, register).
/// Better Auth backend returns access/refresh tokens and user profile.
nonisolated struct AuthResponseDTO: Decodable, Sendable {
    let user: UserDTO
    let accessToken: String
    let refreshToken: String
    let expiresAt: Int?  // Unix timestamp

    func toAuthSession() -> AuthSession {
        let expiresAtDate = expiresAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        return AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            user: UserMapper.toEntity(user),
            expiresAt: expiresAtDate
        )
    }
}

/// DTO for token refresh response.
nonisolated struct RefreshTokenDTO: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Int?
}