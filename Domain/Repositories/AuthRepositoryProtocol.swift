//
//  AuthRepositoryProtocol.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - AuthRepositoryProtocol

protocol AuthRepositoryProtocol: Sendable {

    /// Login with email and password.
    func login(email: String, password: String) async throws -> AuthSession

    /// Register a new account.
    func register(name: String, email: String, password: String, phone: String) async throws -> AuthSession

    /// Refresh the current access token.
    func refreshToken() async throws -> AuthSession

    /// Logout the current session.
    func logout() async throws

    /// Send a forgot-password request.
    func forgotPassword(phoneNumber: String) async throws

    /// Reset password with OTP token.
    func resetPassword(token: String, newPassword: String) async throws

    /// Verify email with token.
    func verifyEmail(token: String) async throws

    /// Resend verification email.
    func resendVerification(email: String) async throws

    /// Change password for authenticated user.
    func changePassword(currentPassword: String, newPassword: String) async throws
}

// MARK: - AuthSession

struct AuthSession: Sendable {
    let accessToken: String
    let refreshToken: String
    let user: User
    let expiresAt: Date?
}
