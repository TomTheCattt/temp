//
//  ChangePasswordUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/9/26.
//

import Foundation

// MARK: - ChangePasswordInput

struct ChangePasswordInput: Sendable {
    let currentPassword: String
    let newPassword: String
    let confirmPassword: String
}

// MARK: - ChangePasswordUseCase

/// Changes the current user's password via the backend API.
protocol ChangePasswordUseCaseProtocol: Sendable {
    func execute(_ input: ChangePasswordInput) async throws
}

final class ChangePasswordUseCase: ChangePasswordUseCaseProtocol, Sendable {

    private let authRepository: AuthRepositoryProtocol

    /// Minimum password length enforced by the backend.
    private let minPasswordLength = 6

    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    func execute(_ input: ChangePasswordInput) async throws {
        // Validation
        guard input.newPassword.count >= minPasswordLength else {
            throw ChangePasswordError.tooShort
        }
        guard input.newPassword == input.confirmPassword else {
            throw ChangePasswordError.mismatch
        }
        guard input.newPassword != input.currentPassword else {
            throw ChangePasswordError.sameAsCurrent
        }

        try await authRepository.changePassword(
            currentPassword: input.currentPassword,
            newPassword: input.newPassword
        )
    }
}

// MARK: - ChangePasswordError

enum ChangePasswordError: LocalizedError {
    case tooShort
    case mismatch
    case sameAsCurrent

    var errorDescription: String? {
        switch self {
        case .tooShort:      return "Password must be at least 6 characters."
        case .mismatch:      return "The new passwords do not match."
        case .sameAsCurrent: return "The new password must be different from the current one."
        }
    }
}