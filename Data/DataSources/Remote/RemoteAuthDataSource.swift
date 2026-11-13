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
/// 2. Backend returns access/refresh tokens in response body (NOT cookies)
final class RemoteAuthDataSource: @unchecked Sendable {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    // MARK: - Login

    /// Sign in with email/password via Better Auth backend.
    /// Tokens are returned in response body (accessToken, refreshToken, expiresAt).
    func login(email: String, password: String) async throws -> AuthSession {
        let (authResponse, _): (AuthResponseDTO, HTTPURLResponse) = try await networkService.requestEnvelopeWithResponse(
            AuthEndpoint.login(email: email, password: password)
        )

        // Use tokens from response body
        guard let accessToken = authResponse.accessToken,
              let refreshToken = authResponse.refreshToken else {
            throw APIError.unauthorized
        }
        return authResponse.toAuthSession(accessToken: accessToken, refreshToken: refreshToken, expiresAt: authResponse.expiresAt)
    }

    // MARK: - Register

    /// Create account with email/password via Better Auth backend.
    /// Tokens are returned in response body (accessToken, refreshToken, expiresAt).
    func register(name: String, email: String, password: String, phone: String?) async throws -> AuthSession {
        let (authResponse, _): (AuthResponseDTO, HTTPURLResponse) = try await networkService.requestEnvelopeWithResponse(
            AuthEndpoint.register(email: email, password: password, username: name, fullName: name, phone: phone)
        )

        // Use tokens from response body
        guard let accessToken = authResponse.accessToken,
              let refreshToken = authResponse.refreshToken else {
            throw APIError.unauthorized
        }
        return authResponse.toAuthSession(accessToken: accessToken, refreshToken: refreshToken, expiresAt: authResponse.expiresAt)
    }

    /// Get a fresh access token from the backend using the refresh token.
    /// Refresh token is sent in Authorization header as Bearer token, new tokens returned in response body.
    func refreshToken(refreshToken: String) async throws -> String {
        let dto: RefreshTokenDTO = try await networkService.refreshAccessToken(refreshToken: refreshToken)
        return dto.accessToken
    }

    /// Get a fresh access token with expiry info.
    func refreshTokenWithExpiry(refreshToken: String) async throws -> (token: String, expiresAt: Date?) {
        let dto: RefreshTokenDTO = try await networkService.refreshAccessToken(refreshToken: refreshToken)
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
/// Backend returns user profile and tokens in response body.
nonisolated struct AuthResponseDTO: Decodable, Sendable {
    let user: UserDTO
    let accessToken: String?
    let refreshToken: String?
    let expiresAt: Int?

    func toAuthSession(accessToken: String, refreshToken: String, expiresAt: Int?) -> AuthSession {
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