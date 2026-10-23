//
//  AuthViewModel.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - AuthViewModel

@MainActor
@Observable
final class AuthViewModel {

    // MARK: - State

    var email = ""
    var password = ""
    var fullName = ""
    var phone = ""
    var confirmPassword = ""

    var isLoading = false
    var errorMessage: String?
    var isLoginMode = true

    // MARK: - Dependencies

    private let loginUseCase: LoginUseCaseProtocol
    private let registerUseCase: RegisterUseCaseProtocol
    private let router: AppRouter

    // MARK: - Init

    init(
        loginUseCase: LoginUseCaseProtocol,
        registerUseCase: RegisterUseCaseProtocol,
        router: AppRouter? = nil
    ) {
        self.loginUseCase = loginUseCase
        self.registerUseCase = registerUseCase
        self.router = router ?? AppRouter.shared

        #if DEBUG
        email = AppConstants.TestAccount.email
        password = AppConstants.TestAccount.password
        #endif
    }

    // MARK: - Computed

    var isLoginValid: Bool {
        email.isValidEmail && password.count >= 6
    }

    var isRegisterValid: Bool {
        !fullName.isEmpty &&
        email.isValidEmail &&
        password.count >= 6 &&
        password == confirmPassword &&
        phone.isValidPhone
    }

    // MARK: - Actions

    func login() async {
        guard isLoginValid else {
            errorMessage = L10n.Auth.invalidLogin
            return
        }
        // TODO: Implement login logic from scratch
    }

    func register() async {
        guard isRegisterValid else {
            errorMessage = L10n.Auth.invalidRegister
            return
        }
        // TODO: Implement register logic from scratch
    }

    func toggleMode() {
        isLoginMode.toggle()
        errorMessage = nil
    }

    func clearError() {
        errorMessage = nil
    }
}
