//
//  ForgotPasswordUseCase.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - ForgotPasswordInput

struct ForgotPasswordInput: Sendable {
    let email: String
}

// MARK: - ForgotPasswordUseCase

protocol ForgotPasswordUseCaseProtocol: Sendable {
    func execute(_ input: ForgotPasswordInput) async throws
}

final class ForgotPasswordUseCase: ForgotPasswordUseCaseProtocol, Sendable {

    private let authRepository: AuthRepositoryProtocol

    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    func execute(_ input: ForgotPasswordInput) async throws {
        // Business validation
        guard input.email.isValidEmail else {
            throw AuthError.invalidEmail
        }

        try await authRepository.forgotPassword(email: input.email)
    }
}

// MARK: - ResetPasswordUseCase

struct ResetPasswordInput: Sendable {
    let token: String
    let newPassword: String
}

protocol ResetPasswordUseCaseProtocol: Sendable {
    func execute(_ input: ResetPasswordInput) async throws
}

final class ResetPasswordUseCase: ResetPasswordUseCaseProtocol, Sendable {

    private let authRepository: AuthRepositoryProtocol

    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    func execute(_ input: ResetPasswordInput) async throws {
        // Business validation
        guard input.newPassword.count >= 6 else {
            throw AuthError.weakPassword
        }

        try await authRepository.resetPassword(token: input.token, newPassword: input.newPassword)
    }
}