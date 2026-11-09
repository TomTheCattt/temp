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
/// 2. Backend issues its own access/refresh tokens (JWT) via HTTP-only cookies
final class RemoteAuthDataSource: @unchecked Sendable {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    // MARK: - Login

    /// Sign in with email/password via Better Auth backend.
    /// Tokens are returned in HTTP-only cookies (Set-Cookie headers).
    func login(email: String, password: String) async throws -> AuthSession {
        let (authResponse, response): (AuthResponseDTO, HTTPURLResponse) = try await networkService.requestEnvelopeWithResponse(
            AuthEndpoint.login(email: email, password: password)
        )

        // Extract tokens from Set-Cookie headers
        let (accessToken, refreshToken, expiresAt) = extractTokens(from: response)
        return authResponse.toAuthSession(accessToken: accessToken, refreshToken: refreshToken, expiresAt: expiresAt)
    }

    // MARK: - Register

    /// Create account with email/password via Better Auth backend.
    /// Tokens are returned in HTTP-only cookies (Set-Cookie headers).
    func register(name: String, email: String, password: String, phone: String?) async throws -> AuthSession {
        let (authResponse, response): (AuthResponseDTO, HTTPURLResponse) = try await networkService.requestEnvelopeWithResponse(
            AuthEndpoint.register(email: email, password: password, username: name, fullName: name, phone: phone)
        )

        // Extract tokens from Set-Cookie headers
        let (accessToken, refreshToken, expiresAt) = extractTokens(from: response)
        return authResponse.toAuthSession(accessToken: accessToken, refreshToken: refreshToken, expiresAt: expiresAt)
    }

    // MARK: - Refresh Token

    /// Get a fresh access token from the backend using the refresh token.
    /// Refresh token is sent via cookie, new tokens returned in response body.
    func refreshToken() async throws -> String {
        let dto: RefreshTokenDTO = try await networkService.requestEnvelope(AuthEndpoint.refresh)

        // Backend returns accessToken, refreshToken, expiresAt
        return dto.accessToken
    }

    /// Get a fresh access token with expiry info.
    func refreshTokenWithExpiry() async throws -> (token: String, expiresAt: Date?) {
        let dto: RefreshTokenDTO = try await networkService.requestEnvelope(AuthEndpoint.refresh)
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

    // MARK: - Private Helpers

    /// Extract access/refresh tokens and expiry from Set-Cookie headers.
    /// Better Auth sets cookies: `instagram-clone.access_token`, `instagram-clone.refresh_token`
    private func extractTokens(from response: HTTPURLResponse) -> (accessToken: String, refreshToken: String, expiresAt: Int?) {
        guard let setCookieHeaders = response.allHeaderFields["Set-Cookie"] as? [String] else {
            // Fallback: try single Set-Cookie header
            if let setCookie = response.allHeaderFields["Set-Cookie"] as? String {
                return parseCookieHeader(setCookie)
            }
            return ("", "", nil)
        }

        var accessToken = ""
        var refreshToken = ""
        var expiresAt: Int?

        for cookie in setCookieHeaders {
            if cookie.contains("instagram-clone.access_token") {
                accessToken = extractCookieValue(cookie, name: "instagram-clone.access_token") ?? ""
            } else if cookie.contains("instagram-clone.refresh_token") {
                refreshToken = extractCookieValue(cookie, name: "instagram-clone.refresh_token") ?? ""
                // Try to extract Max-Age for expiry
                if let maxAge = extractMaxAge(cookie) {
                    expiresAt = Int(Date().timeIntervalSince1970) + maxAge
                }
            }
        }

        return (accessToken, refreshToken, expiresAt)
    }

    private func parseCookieHeader(_ header: String) -> (String, String, Int?) {
        var accessToken = ""
        var refreshToken = ""
        var expiresAt: Int?

        let cookies = header.components(separatedBy: ", ")
        for cookie in cookies {
            if cookie.contains("instagram-clone.access_token") {
                accessToken = extractCookieValue(cookie, name: "instagram-clone.access_token") ?? ""
            } else if cookie.contains("instagram-clone.refresh_token") {
                refreshToken = extractCookieValue(cookie, name: "instagram-clone.refresh_token") ?? ""
                if let maxAge = extractMaxAge(cookie) {
                    expiresAt = Int(Date().timeIntervalSince1970) + maxAge
                }
            }
        }

        return (accessToken, refreshToken, expiresAt)
    }

    private func extractCookieValue(_ cookie: String, name: String) -> String? {
        let pattern = "\(name)=([^;]+)"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: cookie.utf16.count)
        if let match = regex?.firstMatch(in: cookie, options: [], range: range),
           let range = Range(match.range(at: 1), in: cookie) {
            return String(cookie[range])
        }
        return nil
    }

    private func extractMaxAge(_ cookie: String) -> Int? {
        let pattern = "Max-Age=(\\d+)"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: cookie.utf16.count)
        if let match = regex?.firstMatch(in: cookie, options: [], range: range),
           let range = Range(match.range(at: 1), in: cookie),
           let value = Int(cookie[range]) {
            return value
        }
        return nil
    }
}

// MARK: - DTOs

/// DTO for auth API responses (login, register).
/// Better Auth backend returns user profile in body, tokens in HTTP-only cookies.
nonisolated struct AuthResponseDTO: Decodable, Sendable {
    let user: UserDTO
    // Tokens come from Set-Cookie headers, not response body
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