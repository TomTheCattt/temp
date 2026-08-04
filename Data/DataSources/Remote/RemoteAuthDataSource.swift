//
//  RemoteAuthDataSource.swift
//  Instagram
//
//  Created by Kiro on 1/8/26.
//

import Foundation

// MARK: - RemoteAuthDataSource

/// Handles authentication flow:
/// 1. Authenticate with Firebase Auth SDK (get ID token)
/// 2. Send ID token to backend for verification + user profile creation/lookup
final class RemoteAuthDataSource: @unchecked Sendable {

    private let networkService: NetworkServiceProtocol
    private let firebaseAuth: FirebaseAuthServiceProtocol

    init(
        networkService: NetworkServiceProtocol,
        firebaseAuth: FirebaseAuthServiceProtocol = FirebaseAuthService.shared
    ) {
        self.networkService = networkService
        self.firebaseAuth = firebaseAuth
    }

    // MARK: - Login

    /// Sign in with Firebase Auth, then send ID token to backend.
    func login(email: String, password: String) async throws -> AuthSession {
        // Step 1: Authenticate with Firebase
        let firebaseResult = try await firebaseAuth.signIn(email: email, password: password)

        // Step 2: Send ID token to backend for verification
        let dto: AuthResponseDTO = try await networkService.requestEnvelope(
            AuthEndpoint.login(idToken: firebaseResult.idToken)
        )

        // Use Firebase ID token as access token for subsequent API calls
        return AuthSession(
            accessToken: firebaseResult.idToken,
            refreshToken: "",
            user: UserMapper.toEntity(dto.user),
            expiresAt: nil
        )
    }

    // MARK: - Register

    /// Create account with Firebase Auth, then register on backend.
    func register(name: String, email: String, password: String, phone: String?) async throws -> AuthSession {
        // Step 1: Create account with Firebase
        let firebaseResult = try await firebaseAuth.createAccount(email: email, password: password)

        // Step 2: Register user on backend with ID token + profile info
        let dto: AuthResponseDTO = try await networkService.requestEnvelope(
            AuthEndpoint.register(idToken: firebaseResult.idToken, name: name, phone: phone)
        )

        // Use Firebase ID token as access token for subsequent API calls
        return AuthSession(
            accessToken: firebaseResult.idToken,
            refreshToken: "",
            user: UserMapper.toEntity(dto.user),
            expiresAt: nil
        )
    }

    // MARK: - Refresh Token

    /// Get a fresh Firebase ID token (auto-refreshes if expired).
    func refreshToken() async throws -> String {
        try await firebaseAuth.getIDToken()
    }

    // MARK: - Logout

    func logout() async throws {
        try await networkService.requestVoid(AuthEndpoint.logout)
        try firebaseAuth.signOut()
    }

    // MARK: - Other

    func forgotPassword(phoneNumber: String) async throws {
        try await networkService.requestVoid(AuthEndpoint.forgotPassword(phoneNumber: phoneNumber))
    }

    func resetPassword(token: String, newPassword: String) async throws {
        try await networkService.requestVoid(AuthEndpoint.resetPassword(token: token, password: newPassword))
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
}

// MARK: - AuthResponseDTO

/// DTO for auth API responses (login, register).
/// Backend verifies Firebase ID token and returns user profile.
nonisolated struct AuthResponseDTO: Decodable, Sendable {
    let user: UserDTO
    let accessToken: String?   // Optional: backend may issue its own session token
    let refreshToken: String?  // Optional: backend may issue its own refresh token

    func toAuthSession() -> AuthSession {
        AuthSession(
            accessToken: accessToken ?? "",
            refreshToken: refreshToken ?? "",
            user: UserMapper.toEntity(user),
            expiresAt: nil
        )
    }
}
