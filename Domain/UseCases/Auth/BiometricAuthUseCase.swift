//
//  BiometricAuthUseCase.swift
//  Instagram
//
//  Created by Kiro on 3/11/26.
//

import Foundation
import LocalAuthentication

// MARK: - BiometricAuthUseCase

protocol BiometricAuthUseCaseProtocol: Sendable {
    /// Check if biometric authentication is available and enabled.
    func isBiometricAvailable() -> Bool

    /// Authenticate with biometrics to unlock the app/access account.
    /// Returns the stored credentials (email/password) on success.
    func authenticateWithBiometrics() async throws -> (email: String, password: String)

    /// Store credentials for biometric login.
    func storeCredentialsForBiometricLogin(email: String, password: String)

    /// Remove stored biometric credentials.
    func clearBiometricCredentials()

    /// Enable/disable biometric authentication.
    func setBiometricEnabled(_ enabled: Bool)

    /// Check if biometric is enabled.
    var isBiometricEnabled: Bool { get }
}

final class BiometricAuthUseCase: BiometricAuthUseCaseProtocol, Sendable {

    private let biometricAuthenticator: BiometricAuthenticating
    private let keychainManager: KeychainManagerProtocol

    private let biometricEmailKey: String
    private let biometricPasswordKey: String
    private let biometricEnabledKey: String

    init(
        biometricAuthenticator: BiometricAuthenticating,
        keychainManager: KeychainManagerProtocol
    ) {
        self.biometricAuthenticator = biometricAuthenticator
        self.keychainManager = keychainManager
        let prefix = AppConstants.Keychain.service
        self.biometricEmailKey = "\(prefix).auth.biometricEmail"
        self.biometricPasswordKey = "\(prefix).auth.biometricPassword"
        self.biometricEnabledKey = "\(prefix).auth.biometricEnabled"
    }

    var isBiometricEnabled: Bool {
        keychainManager.get(key: biometricEnabledKey) == "true"
    }

    func isBiometricAvailable() -> Bool {
        biometricAuthenticator.canAuthenticate(policy: .biometricsOrDevicePasscode)
    }

    func authenticateWithBiometrics() async throws -> (email: String, password: String) {
        // Check if biometric is enabled and available
        guard isBiometricEnabled else {
            throw BiometricAuthError.notEnabled
        }

        guard isBiometricAvailable() else {
            throw BiometricAuthError.notAvailable
        }

        // Authenticate with biometrics
        let success = try await biometricAuthenticator.authenticate(
            reason: "Sign in to Instagram",
            policy: .biometricsOrDevicePasscode
        )

        guard success else {
            throw BiometricAuthError.authenticationFailed
        }

        // Retrieve stored credentials
        guard let email = keychainManager.get(key: biometricEmailKey),
              let password = keychainManager.get(key: biometricPasswordKey) else {
            throw BiometricAuthError.credentialsNotFound
        }

        return (email, password)
    }

    func storeCredentialsForBiometricLogin(email: String, password: String) {
        guard isBiometricEnabled else { return }
        keychainManager.set(value: email, key: biometricEmailKey)
        keychainManager.set(value: password, key: biometricPasswordKey)
    }

    func clearBiometricCredentials() {
        keychainManager.delete(key: biometricEmailKey)
        keychainManager.delete(key: biometricPasswordKey)
    }

    func setBiometricEnabled(_ enabled: Bool) {
        keychainManager.set(value: enabled ? "true" : "false", key: biometricEnabledKey)
        if !enabled {
            clearBiometricCredentials()
        }
    }
}

// MARK: - BiometricAuthError

enum BiometricAuthError: LocalizedError {
    case notEnabled
    case notAvailable
    case authenticationFailed
    case credentialsNotFound
    case userCancelled

    var errorDescription: String? {
        switch self {
        case .notEnabled:
            return "Biometric authentication is not enabled."
        case .notAvailable:
            return "Biometric authentication is not available on this device."
        case .authenticationFailed:
            return "Biometric authentication failed. Please try again or use email/password."
        case .credentialsNotFound:
            return "No stored credentials found for biometric login."
        case .userCancelled:
            return "Biometric authentication was cancelled."
        }
    }
}