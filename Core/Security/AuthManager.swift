//
//  AuthManager.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - AuthManagerProtocol

@MainActor
protocol AuthManagerProtocol: AnyObject, Sendable {
    var accessToken: String? { get }
    var isAuthenticated: Bool { get }

    func storeSession(_ session: AuthSession)
    func refreshToken() async throws
    func logout()
}

// MARK: - AuthManager

/// Manages authentication state.
/// In live mode: accessToken is the Firebase ID token (auto-refreshed via Firebase SDK).
/// In mock mode: accessToken is a mock string stored in Keychain.
@MainActor
final class AuthManager: AuthManagerProtocol {

    private let keychainManager: KeychainManager
    private let firebaseAuth: FirebaseAuthServiceProtocol

    private(set) var accessToken: String?

    var isAuthenticated: Bool { accessToken != nil }

    init(
        keychainManager: KeychainManager,
        firebaseAuth: FirebaseAuthServiceProtocol = FirebaseAuthService.shared
    ) {
        self.keychainManager = keychainManager
        self.firebaseAuth = firebaseAuth
        loadStoredTokens()
    }

    // MARK: - Store Session

    func storeSession(_ session: AuthSession) {
        accessToken = session.accessToken
        keychainManager.set(value: session.accessToken, key: KeychainKeys.accessToken)
    }

    // MARK: - Refresh Token

    /// Refresh the access token.
    /// In live mode: Firebase SDK returns a fresh ID token (handles expiry internally).
    /// In mock mode: generates a fake token.
    func refreshToken() async throws {
        if AppConfig.shared.isMockAPI {
            // Mock: generate a fake refreshed token
            let newToken = "mock_refreshed_\(UUID().uuidString.prefix(8))"
            accessToken = newToken
            keychainManager.set(value: newToken, key: KeychainKeys.accessToken)
            return
        }

        // Live: get fresh Firebase ID token
        let freshToken = try await firebaseAuth.getIDToken()
        accessToken = freshToken
        keychainManager.set(value: freshToken, key: KeychainKeys.accessToken)
    }

    // MARK: - Logout

    func logout() {
        accessToken = nil
        keychainManager.delete(key: KeychainKeys.accessToken)

        // Sign out from Firebase
        try? firebaseAuth.signOut()

        // Clear session data
        SessionStore.shared.clear()

        // Reset navigation
        AppRouter.shared.isAuthenticated = false
        AppRouter.shared.reset()
    }

    // MARK: - Private

    private func loadStoredTokens() {
        accessToken = keychainManager.get(key: KeychainKeys.accessToken)
    }
}
