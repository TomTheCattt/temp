//
//  ResetPasswordViewModel.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - ResetPasswordViewModel

@MainActor
@Observable
final class ResetPasswordViewModel {

    // MARK: - State
    var newPassword = ""
    var confirmPassword = ""
    var isLoading = false
    var errorMessage: String?
    var isReset = false
    var showSuccessAlert = false

    // MARK: - Dependencies
    private let resetPasswordUseCase: ResetPasswordUseCaseProtocol
    private let token: String

    // MARK: - Init
    init(resetPasswordUseCase: ResetPasswordUseCaseProtocol, token: String) {
        self.resetPasswordUseCase = resetPasswordUseCase
        self.token = token
    }

    // MARK: - Computed
    var isFormValid: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword
    }

    // MARK: - Actions
    func resetPassword() async {
        guard isFormValid else {
            errorMessage = newPassword.count < 6 ? "Password must be at least 6 characters" : "Passwords do not match"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await resetPasswordUseCase.execute(ResetPasswordInput(token: token, newPassword: newPassword))
            isReset = true
            showSuccessAlert = true
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Helpers
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            errorMessage = apiError.localizedDescription
        } else if let authError = error as? AuthError {
            errorMessage = authError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
    }
}