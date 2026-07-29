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
            errorMessage = "Please enter a valid email and password."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let session = try await loginUseCase.execute(
                LoginInput(email: email, password: password)
            )
            handleAuthSuccess(session)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func register() async {
        guard isRegisterValid else {
            errorMessage = "Please fill in all fields correctly."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let session = try await registerUseCase.execute(
                RegisterInput(
                    name: fullName,
                    email: email,
                    password: password,
                    phone: phone
                )
            )
            handleAuthSuccess(session)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleMode() {
        isLoginMode.toggle()
        errorMessage = nil
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private

    private func handleAuthSuccess(_ session: AuthSession) {
        // TODO: Store tokens via KeychainManager
        router.isAuthenticated = true
    }
}
