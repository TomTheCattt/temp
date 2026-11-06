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
        let (userDTO, httpResponse) = try await networkService.requestEnvelopeWithResponse(
            AuthEndpoint.login(email: email, password: password)
        ) as (UserDTO, HTTPURLResponse)

        // Extract tokens from Set-Cookie headers (Better Auth uses HTTP-only cookies)
        let (accessToken, refreshToken, expiresAt) = extractTokens(from: httpResponse)

        return AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            user: UserMapper.toEntity(userDTO),
            expiresAt: expiresAt
        )
    }

    // MARK: - Register

    /// Create account with email/password via Better Auth backend.
    func register(name: String, email: String, password: String, phone: String?) async throws -> AuthSession {
        let (userDTO, httpResponse) = try await networkService.requestEnvelopeWithResponse(
            AuthEndpoint.register(email: email, password: password, username: name, fullName: name, phone: phone)
        ) as (UserDTO, HTTPURLResponse)

        // Extract tokens from Set-Cookie headers (Better Auth uses HTTP-only cookies)
        let (accessToken, refreshToken, expiresAt) = extractTokens(from: httpResponse)

        return AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            user: UserMapper.toEntity(userDTO),
            expiresAt: expiresAt
        )
    }

    // MARK: - Refresh Token

    /// Get a fresh access token from the backend using the refresh token.
    func refreshToken() async throws -> String {
        let (dto, httpResponse) = try await networkService.requestEnvelopeWithResponse(
            AuthEndpoint.refresh
        ) as (RefreshTokenDTO, HTTPURLResponse)

        // Update tokens from cookies if present
        if let newAccessToken = extractAccessToken(from: httpResponse) {
            return newAccessToken
        }
        return dto.accessToken
    }

    /// Get a fresh access token with expiry info.
    func refreshTokenWithExpiry() async throws -> (token: String, expiresAt: Date?) {
        let (dto, httpResponse) = try await networkService.requestEnvelopeWithResponse(
            AuthEndpoint.refresh
        ) as (RefreshTokenDTO, HTTPURLResponse)

        let newAccessToken = extractAccessToken(from: httpResponse) ?? dto.accessToken
        let expiresAt = dto.expiresAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        return (newAccessToken, expiresAt)
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

    // MARK: - Private Helpers

    /// Extract tokens from Set-Cookie headers (Better Auth format)
    private func extractTokens(from response: HTTPURLResponse) -> (accessToken: String, refreshToken: String, expiresAt: Date?) {
        guard let cookieHeader = response.allHeaderFields["Set-Cookie"] as? String else {
            // Fallback: try to get from multiple Set-Cookie headers
            return extractTokensFromMultipleHeaders(response)
        }
        return parseCookies(cookieHeader)
    }

    /// Extract tokens from multiple Set-Cookie headers
    private func extractTokensFromMultipleHeaders(_ response: HTTPURLResponse) -> (accessToken: String, refreshToken: String, expiresAt: Date?) {
        var accessToken = ""
        var refreshToken = ""
        var expiresAt: Date?

        // Check all header fields for Set-Cookie
        for (key, value) in response.allHeaderFields {
            if let keyString = key as? String,
               keyString.lowercased() == "set-cookie",
               let cookieString = value as? String {
                let (at, rt, exp) = parseCookies(cookieString)
                if !at.isEmpty { accessToken = at }
                if !rt.isEmpty { refreshToken = rt }
                if exp != nil { expiresAt = exp }
            }
        }

        // If still empty, try to get from response cookies (if Alamofire stores them)
        if accessToken.isEmpty || refreshToken.isEmpty {
            // Note: Alamofire doesn't automatically store HTTP-only cookies from response
            // They are only in the Set-Cookie headers
        }

        return (accessToken, refreshToken, expiresAt)
    }

    /// Parse Better Auth cookies from cookie string
    /// Expected cookies: better-auth.access_token, better-auth.refresh_token, better-auth.session
    private func parseCookies(_ cookieString: String) -> (accessToken: String, refreshToken: String, expiresAt: Date?) {
        var accessToken = ""
        var refreshToken = ""
        var expiresAt: Date?

        let cookies = cookieString.components(separatedBy: "; ")
        for cookie in cookies {
            let parts = cookie.components(separatedBy: "=")
            guard parts.count == 2 else { continue }
            let name = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)

            switch name {
            case "better-auth.access_token":
                accessToken = value
            case "better-auth.refresh_token":
                refreshToken = value
            case "better-auth.session":
                // Session cookie may contain expiry info
                // Value format: session_data|expiry_timestamp
                let sessionParts = value.split(separator: "|")
                if sessionParts.count == 2, let timestamp = Int(sessionParts[1]) {
                    expiresAt = Date(timeIntervalSince1970: TimeInterval(timestamp))
                }
            default:
                break
            }
        }

        return (accessToken, refreshToken, expiresAt)
    }

    /// Extract only access token from response cookies
    private func extractAccessToken(from response: HTTPURLResponse) -> String? {
        guard let cookieHeader = response.allHeaderFields["Set-Cookie"] as? String else {
            return nil
        }
        let cookies = cookieHeader.components(separatedBy: "; ")
        for cookie in cookies {
            let parts = cookie.components(separatedBy: "=")
            guard parts.count == 2 else { continue }
            let name = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)
            if name == "better-auth.access_token" {
                return value
            }
        }
        return nil
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