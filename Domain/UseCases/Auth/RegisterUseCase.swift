//
//  RegisterUseCase.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - RegisterInput

struct RegisterInput: Sendable {
    let name: String
    let email: String
    let password: String
    let phone: String
}

// MARK: - RegisterUseCase

protocol RegisterUseCaseProtocol: Sendable {
    func execute(_ input: RegisterInput) async throws -> AuthSession
}

final class RegisterUseCase: RegisterUseCaseProtocol, Sendable {

    private let authRepository: AuthRepositoryProtocol

    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    func execute(_ input: RegisterInput) async throws -> AuthSession {
        guard input.name.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty else {
            throw ValidationError.emptyField("name")
        }
        guard input.email.isValidEmail else {
            throw AuthError.invalidEmail
        }
        guard input.password.count >= 6 else {
            throw AuthError.weakPassword
        }
        guard input.phone.isValidPhone else {
            throw AuthError.invalidPhone
        }

        return try await authRepository.register(
            name: input.name,
            email: input.email,
            password: input.password,
            phone: input.phone
        )
    }
}

// MARK: - ValidationError

enum ValidationError: LocalizedError {
    case emptyComment
    case commentTooLong
    case emptyField(String)

    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "\(field.capitalized) cannot be empty."
        case .emptyComment:  return "Comment cannot be empty."
        case .commentTooLong: return "Comment exceeds maximum length (2200 characters)."
        }
    }
}
