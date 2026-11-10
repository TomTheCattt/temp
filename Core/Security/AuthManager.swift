//
///  AuthManager.swift
///  Instagram
///
///  Created by Kiro on 26/7/26.
//

import Foundation
import Alamofire

// MARK: - AuthManagerProtocol

@MainActor
protocol AuthManagerProtocol: AnyObject, Sendable {
    var accessToken: String? { get }
    var refreshToken: String? { get }
    var isAuthenticated: Bool { get }
    var tokenExpiry: Date? { get }

    func storeSession(_ session: AuthSession)
    func refreshToken() async throws
    func refreshTokenIfNeeded() async throws
    func validateTokenAndFetchProfile() async throws -> User?
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

/// Manages authentication state.
/// Access and refresh tokens are stored securely in Keychain.
@MainActor
final class AuthManager: AuthManagerProtocol {

    private let keychainManager: KeychainManagerProtocol
    private let networkService: NetworkServiceProtocol

    private(set) var accessToken: String?
    private(set) var refreshToken: String?
    private(set) var tokenExpiry: Date?

    var isAuthenticated: Bool { accessToken != nil }

    // Token is considered near expiry 5 minutes before actual expiry
    private let expiryBuffer: TimeInterval = 5 * 60

    init(
        keychainManager: KeychainManagerProtocol,
        networkService: NetworkServiceProtocol
    ) {
        self.keychainManager = keychainManager
        self.networkService = networkService
        loadStoredTokens()
    }

    // MARK: - Token Validation & Session Restoration

    /// Validate the current access token with the backend and fetch fresh user profile.
    /// Call this on app launch after loading stored tokens.
    func validateTokenAndFetchProfile() async throws -> User? {
        guard let _ = accessToken else {
            throw APIError.unauthorized
        }

        do {
            // Try to fetch current user profile - this validates the token
            let wrapper: UserWrapperDTO = try await networkService.requestEnvelope(
                UserEndpoint.profile
            )
            let user = UserMapper.toEntity(wrapper.user)

            // Update SessionStore with fresh user data
            SessionStore.shared.setSession(user: user)

            // Refresh token if needed after successful validation
            try await refreshTokenIfNeeded()

            return user
        } catch {
            // Token is invalid or expired - try to refresh
            do {
                try await refreshToken()
                // Retry fetching profile with new token
                let wrapper: UserWrapperDTO = try await networkService.requestEnvelope(
                    UserEndpoint.profile
                )
                let user = UserMapper.toEntity(wrapper.user)
                SessionStore.shared.setSession(user: user)
                return user
            } catch {
                // Refresh failed - logout
                logout(reason: .sessionExpired)
                throw APIError.unauthorized
            }
        }
    }

    // MARK: - Store Session

    func storeSession(_ session: AuthSession) {
        accessToken = session.accessToken
        refreshToken = session.refreshToken
        tokenExpiry = session.expiresAt
        keychainManager.set(value: session.accessToken, key: KeychainKeys.accessToken)
        keychainManager.set(value: session.refreshToken, key: KeychainKeys.refreshToken)
        if let expiry = session.expiresAt {
            keychainManager.set(value: String(expiry.timeIntervalSince1970), key: KeychainKeys.tokenExpiry)
        }
    }

    // MARK: - Refresh Token

    /// Refresh the access token via backend API using the refresh token.
    func refreshToken() async throws {
        guard let currentRefreshToken = refreshToken else {
            throw APIError.unauthorized
        }

        // Create a temporary request with the refresh token
        let urlRequest = try AuthEndpoint.refresh.asURLRequest()
        var request = urlRequest
        request.setValue("Bearer \(currentRefreshToken)", forHTTPHeaderField: "Authorization")

        let response = await networkService.session
            .request(request)
            .validate(statusCode: 200..<300)
            .serializingDecodable(APIEnvelope<RefreshTokenDTO>.self, decoder: networkService.decoder)
            .response

        switch response.result {
        case .success(let envelope):
            guard let data = envelope.data else {
                if let errorMessage = envelope.error ?? envelope.message {
                    throw APIError.serverError(errorMessage)
                }
                throw APIError.unknown(response.response?.statusCode)
            }
            accessToken = data.accessToken
            if let newRefreshToken = data.refreshToken {
                refreshToken = newRefreshToken
                keychainManager.set(value: newRefreshToken, key: KeychainKeys.refreshToken)
            }
            if let expiresAt = data.expiresAt {
                tokenExpiry = Date(timeIntervalSince1970: TimeInterval(expiresAt))
                keychainManager.set(value: String(expiresAt), key: KeychainKeys.tokenExpiry)
            }
            keychainManager.set(value: data.accessToken, key: KeychainKeys.accessToken)

        case .failure(let afError):
            throw mapError(afError, response: response.response)
        }
    }

    /// Proactively refresh token if it's near expiry (within 5 minutes).
    func refreshTokenIfNeeded() async throws {
        guard let expiry = tokenExpiry else { return }
        let timeUntilExpiry = expiry.timeIntervalSinceNow
        if timeUntilExpiry < expiryBuffer {
            try await refreshToken()
        }
    }

    // MARK: - Logout

    func logout(reason: LogoutReason) {
        accessToken = nil
        refreshToken = nil
        tokenExpiry = nil
        keychainManager.delete(key: KeychainKeys.accessToken)
        keychainManager.delete(key: KeychainKeys.refreshToken)
        keychainManager.delete(key: KeychainKeys.tokenExpiry)

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
        refreshToken = keychainManager.get(key: KeychainKeys.refreshToken)
        if let expiryString = keychainManager.get(key: KeychainKeys.tokenExpiry),
           let timeInterval = TimeInterval(expiryString) {
            tokenExpiry = Date(timeIntervalSince1970: timeInterval)
        }
    }

    // Reuse the decoder from NetworkService
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return decoder
    }

    private func mapError(_ afError: AFError, response: HTTPURLResponse?) -> APIError {
        APIError.from(afError, response: response)
    }
}