//
//  LoginUseCase.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - LoginInput

struct LoginInput: Sendable {
    let email: String
    let password: String
}

// MARK: - LoginUseCase

protocol LoginUseCaseProtocol: Sendable {
    func execute(_ input: LoginInput) async throws -> AuthSession
}

final class LoginUseCase: LoginUseCaseProtocol, Sendable {

    private let authRepository: AuthRepositoryProtocol

    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    func execute(_ input: LoginInput) async throws -> AuthSession {
        // Business validation
        guard input.email.isValidEmail else {
            throw AuthError.invalidEmail
        }
        guard input.password.count >= 6 else {
            throw AuthError.weakPassword
        }

        return try await authRepository.login(
            email: input.email,
            password: input.password
        )
    }
}

// MARK: - AuthError

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case invalidPhone
    case invalidOTP

    var errorDescription: String? {
        switch self {
        case .invalidEmail:  return "Invalid email address."
        case .weakPassword:  return "Password must be at least 6 characters."
        case .invalidPhone:  return "Invalid phone number."
        case .invalidOTP:    return "Invalid verification code."
        }
    }
}
