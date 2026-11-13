//
//  VerifyEmailViewModel.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - VerifyEmailViewModel

@MainActor
@Observable
final class VerifyEmailViewModel {

    // MARK: - State
    var token = ""
    var otpDigits: [Character] = Array(repeating: " ", count: 6)
    var focusedIndex = 0
    var isLoading = false
    var errorMessage: String?
    var isVerified = false
    var showSuccessAlert = false
    var requiresOTP = true // Can be toggled based on flow
    var showError = false

    // Resend
    var isResending = false
    var resendCountdown = 0
    private var resendTimerTask: Task<Void, Never>?

    // MARK: - Dependencies
    private let verifyEmailUseCase: VerifyEmailUseCaseProtocol
    private let resendVerificationUseCase: ResendVerificationUseCaseProtocol

    // MARK: - Init
    init(
        verifyEmailUseCase: VerifyEmailUseCaseProtocol,
        resendVerificationUseCase: ResendVerificationUseCaseProtocol,
        token: String? = nil
    ) {
        self.verifyEmailUseCase = verifyEmailUseCase
        self.resendVerificationUseCase = resendVerificationUseCase

        if let token {
            self.token = token
            self.requiresOTP = false
        }
    }

    // MARK: - Computed
    var isFormValid: Bool {
        if requiresOTP {
            return otpDigits.allSatisfy { $0 != " " }
        }
        return token.count >= 6
    }

    // MARK: - Actions
    func verifyEmail() async {
        guard isFormValid else {
            showError = true
            errorMessage = L10n.VerifyEmail.invalidToken
            return
        }

        isLoading = true
        errorMessage = nil
        showError = false

        let tokenToVerify = requiresOTP ? String(otpDigits) : token

        do {
            try await verifyEmailUseCase.execute(VerifyEmailInput(token: tokenToVerify))
            isVerified = true
            showSuccessAlert = true
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    func resendVerification() async {
        // We need the email - this would typically come from the previous screen
        // For now, we'll use a placeholder or store it in the view model
        isResending = true

        do {
            // In a real app, we'd pass the email from the registration flow
            try await resendVerificationUseCase.execute(ResendVerificationInput(email: ""))
            startResendCountdown()
            ToastManager.shared.success(L10n.VerifyEmail.resentSuccess)
        } catch {
            handleError(error)
        }

        isResending = false
    }

    func updateOTPDigit(at index: Int, with newValue: String) {
        let digit = newValue.prefix(1)
        if index < otpDigits.count {
            otpDigits[index] = digit.first ?? " "
        }

        // Auto-advance focus
        if !digit.isEmpty && index < 5 {
            focusedIndex = index + 1
        } else if digit.isEmpty && index > 0 {
            focusedIndex = index - 1
        }

        showError = false
    }

    func clearError() {
        errorMessage = nil
        showError = false
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
        showError = true
    }

    private func startResendCountdown() {
        resendCountdown = 60
        resendTimerTask?.cancel()
        resendTimerTask = Task { @MainActor [weak self] in
            while let self, self.resendCountdown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                self.resendCountdown -= 1
            }
        }
    }

    func cancelResendCountdown() {
        resendTimerTask?.cancel()
        resendTimerTask = nil
    }
}