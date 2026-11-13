//
//  ForgotPasswordViewModel.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - ForgotPasswordViewModel

@MainActor
@Observable
final class ForgotPasswordViewModel {

    // MARK: - State
    var email = ""
    var isLoading = false
    var errorMessage: String?
    var isSent = false
    var showSuccessAlert = false

    // MARK: - Dependencies
    private let forgotPasswordUseCase: ForgotPasswordUseCaseProtocol

    // MARK: - Init
    init(forgotPasswordUseCase: ForgotPasswordUseCaseProtocol) {
        self.forgotPasswordUseCase = forgotPasswordUseCase
    }

    // MARK: - Computed
    var isFormValid: Bool {
        email.isValidEmail
    }

    // MARK: - Actions
    func sendResetEmail() async {
        guard isFormValid else {
            errorMessage = L10n.Auth.invalidLogin
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await forgotPasswordUseCase.execute(ForgotPasswordInput(email: email))
            isSent = true
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