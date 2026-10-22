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
    func logout(reason: LogoutReason)
}

extension AuthManagerProtocol {
    /// Convenience: default logout is user-initiated (no toast).
    func logout() {
        logout(reason: .userInitiated)
    }
}

// MARK: - LogoutReason

/// Why a logout happened — controls whether the user is notified.
enum LogoutReason: Sendable {
    /// User tapped "Log out" — no notification needed.
    case userInitiated
    /// Session expired / token refresh failed (forced) — notify the user.
    case sessionExpired
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
        firebaseAuth: FirebaseAuthServiceProtocol? = nil
    ) {
        self.keychainManager = keychainManager
        self.firebaseAuth = FirebaseAuthService.shared
        loadStoredTokens()
    }

    // MARK: - Store Session

    func storeSession(_ session: AuthSession) {
        accessToken = session.accessToken
        keychainManager.set(value: session.accessToken, key: KeychainKeys.accessToken)
    }

    // MARK: - Refresh Token

    /// Refresh the access token via Firebase Auth SDK (handles expiry internally).
    func refreshToken() async throws {
        let freshToken = try await firebaseAuth.getIDToken()
        accessToken = freshToken
        keychainManager.set(value: freshToken, key: KeychainKeys.accessToken)
    }

    // MARK: - Logout

    func logout(reason: LogoutReason) {
        accessToken = nil
        keychainManager.delete(key: KeychainKeys.accessToken)

        // Sign out from Firebase
        try? firebaseAuth.signOut()

        // Clear session data
        SessionStore.shared.clear()

        // Reset navigation
        AppRouter.shared.isAuthenticated = false
        AppRouter.shared.reset()

        // Notify the user only on a forced (unexpected) logout.
        if reason == .sessionExpired {
            ToastManager.shared.warning(L10n.Error.sessionExpired)
        }
    }

    // MARK: - Private

    private func loadStoredTokens() {
        accessToken = keychainManager.get(key: KeychainKeys.accessToken)
    }
}
