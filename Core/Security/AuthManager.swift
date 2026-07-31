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
    var refreshToken: String? { get }
    var isAuthenticated: Bool { get }

    func storeSession(_ session: AuthSession)
    func refreshToken() async throws
    func logout()
}

// MARK: - AuthManager

@MainActor
final class AuthManager: AuthManagerProtocol {

    private let keychainManager: KeychainManager

    private(set) var accessToken: String?
    private(set) var refreshToken: String?

    var isAuthenticated: Bool { accessToken != nil }

    init(keychainManager: KeychainManager) {
        self.keychainManager = keychainManager
        loadStoredTokens()
    }

    // MARK: - Store

    func storeSession(_ session: AuthSession) {
        accessToken = session.accessToken
        refreshToken = session.refreshToken

        keychainManager.set(value: session.accessToken, key: KeychainKeys.accessToken)
        keychainManager.set(value: session.refreshToken, key: KeychainKeys.refreshToken)
    }

    // MARK: - Refresh

    func refreshToken() async throws {
        guard let _ = refreshToken else {
            throw APIError.unauthorized
        }

        // In production, call the auth API
        // For mock: just simulate
        try await Task.sleep(nanoseconds: 500_000_000)

        let newAccess = "refreshed_\(UUID().uuidString.prefix(8))"
        accessToken = newAccess
        keychainManager.set(value: newAccess, key: KeychainKeys.accessToken)
    }

    // MARK: - Logout

    func logout() {
        accessToken = nil
        refreshToken = nil
        keychainManager.delete(key: KeychainKeys.accessToken)
        keychainManager.delete(key: KeychainKeys.refreshToken)

        // Clear session data
        SessionStore.shared.clear()

        // Reset navigation
        AppRouter.shared.isAuthenticated = false
        AppRouter.shared.reset()
    }

    // MARK: - Private

    private func loadStoredTokens() {
        accessToken = keychainManager.get(key: KeychainKeys.accessToken)
        refreshToken = keychainManager.get(key: KeychainKeys.refreshToken)
    }
}
