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
    var isBiometricLoginAvailable = false
    var isBiometricEnabled = false

    // MARK: - Dependencies

    private let loginUseCase: LoginUseCaseProtocol
    private let registerUseCase: RegisterUseCaseProtocol
    private let biometricAuthUseCase: BiometricAuthUseCaseProtocol
    private let router: AppRouter
    private let webSocketConnectionManager: WebSocketConnectionManagerProtocol

    // MARK: - Init

    init(
        loginUseCase: LoginUseCaseProtocol,
        registerUseCase: RegisterUseCaseProtocol,
        biometricAuthUseCase: BiometricAuthUseCaseProtocol,
        webSocketConnectionManager: WebSocketConnectionManagerProtocol,
        router: AppRouter? = nil
    ) {
        self.loginUseCase = loginUseCase
        self.registerUseCase = registerUseCase
        self.biometricAuthUseCase = biometricAuthUseCase
        self.webSocketConnectionManager = webSocketConnectionManager
        self.router = router ?? AppRouter.shared

        #if DEBUG
        email = AppConstants.TestAccount.email
        password = AppConstants.TestAccount.password
        #endif

        checkBiometricAvailability()
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

        isLoading = true
        errorMessage = nil

        do {
            let session = try await loginUseCase.execute(LoginInput(email: email, password: password))
            // Store credentials for biometric login if enabled
            biometricAuthUseCase.storeCredentialsForBiometricLogin(email: email, password: password)
            handleAuthSuccess(session)
        } catch {
            handleAuthError(error)
        }

        isLoading = false
    }

    func register() async {
        guard isRegisterValid else {
            errorMessage = L10n.Auth.invalidRegister
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let session = try await registerUseCase.execute(
                RegisterInput(name: fullName, email: email, password: password, phone: phone)
            )
            // Store credentials for biometric login if enabled
            biometricAuthUseCase.storeCredentialsForBiometricLogin(email: email, password: password)
            handleAuthSuccess(session)
        } catch {
            handleAuthError(error)
        }

        isLoading = false
    }

    func loginWithBiometrics() async {
        guard isBiometricEnabled && isBiometricLoginAvailable else { return }

        isLoading = true
        errorMessage = nil

        do {
            let credentials = try await biometricAuthUseCase.authenticateWithBiometrics()
            let session = try await loginUseCase.execute(
                LoginInput(email: credentials.email, password: credentials.password)
            )
            handleAuthSuccess(session)
        } catch {
            handleAuthError(error)
        }

        isLoading = false
    }

    func toggleBiometricLogin() {
        isBiometricEnabled.toggle()
        biometricAuthUseCase.setBiometricEnabled(isBiometricEnabled)
        if !isBiometricEnabled {
            biometricAuthUseCase.clearBiometricCredentials()
        }
        checkBiometricAvailability()
    }

    func toggleMode() {
        isLoginMode.toggle()
        errorMessage = nil
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Helpers

    private func handleAuthSuccess(_ session: AuthSession) {
        // AuthManager and SessionStore are updated by the repository
        // Navigate to main app
        router.isAuthenticated = true
        router.dismiss()

        // Connect to WebSocket after successful authentication
        webSocketConnectionManager.handleAuthStateChange(isAuthenticated: true)
    }

    private func handleAuthError(_ error: Error) {
        if let authError = error as? AuthError {
            errorMessage = authError.errorDescription
        } else if let biometricError = error as? BiometricAuthError {
            errorMessage = biometricError.errorDescription
        } else if let apiError = error as? APIError {
            errorMessage = apiError.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
    }

    private func checkBiometricAvailability() {
        isBiometricLoginAvailable = biometricAuthUseCase.isBiometricAvailable()
        isBiometricEnabled = biometricAuthUseCase.isBiometricEnabled
    }
}
