//
//  VerifyEmailUseCase.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - VerifyEmailInput

struct VerifyEmailInput: Sendable {
    let token: String
}

// MARK: - VerifyEmailUseCase

protocol VerifyEmailUseCaseProtocol: Sendable {
    func execute(_ input: VerifyEmailInput) async throws
}

final class VerifyEmailUseCase: VerifyEmailUseCaseProtocol, Sendable {

    private let authRepository: AuthRepositoryProtocol

    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    func execute(_ input: VerifyEmailInput) async throws {
        try await authRepository.verifyEmail(token: input.token)
    }
}

// MARK: - ResendVerificationUseCase

struct ResendVerificationInput: Sendable {
    let email: String
}

protocol ResendVerificationUseCaseProtocol: Sendable {
    func execute(_ input: ResendVerificationInput) async throws
}

final class ResendVerificationUseCase: ResendVerificationUseCaseProtocol, Sendable {

    private let authRepository: AuthRepositoryProtocol

    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    func execute(_ input: ResendVerificationInput) async throws {
        // Business validation
        guard input.email.isValidEmail else {
            throw AuthError.invalidEmail
        }

        try await authRepository.resendVerification(email: input.email)
    }
}