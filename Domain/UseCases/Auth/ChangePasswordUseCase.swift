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

/// Changes the current user's password.
///
/// Per the backend contract, password changes are performed client-side via the
/// Firebase Auth SDK (`updatePassword`), which requires a recent reauthentication
/// with the current password. This use case validates input, then delegates to
/// `FirebaseAuthServiceProtocol`. In mock mode it simulates success.
protocol ChangePasswordUseCaseProtocol: Sendable {
    func execute(_ input: ChangePasswordInput) async throws
}

final class ChangePasswordUseCase: ChangePasswordUseCaseProtocol, Sendable {

    private let firebaseAuth: FirebaseAuthServiceProtocol
    private let isMockMode: Bool

    /// Minimum password length enforced by Firebase.
    private let minPasswordLength = 6

    init(
        firebaseAuth: FirebaseAuthServiceProtocol,
        isMockMode: Bool = AppConfig.shared.isMockAPI
    ) {
        self.firebaseAuth = firebaseAuth
        self.isMockMode = isMockMode
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

        if isMockMode {
            // Simulate network/SDK latency in mock mode.
            try await Task.sleep(nanoseconds: 600_000_000)
            return
        }

        try await firebaseAuth.updatePassword(
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
