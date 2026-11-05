//
//  FirebaseAuthService.swift
//  Instagram
//
//  Created by Kiro on 1/8/26.
//

import Foundation
import FirebaseAuth

// MARK: - FirebaseAuthServiceProtocol

protocol FirebaseAuthServiceProtocol: Sendable {
    /// Sign in with email/password via Firebase Auth. Returns Firebase ID token.
    func signIn(email: String, password: String) async throws -> FirebaseAuthResult

    /// Create a new account with email/password via Firebase Auth. Returns Firebase ID token.
    func createAccount(email: String, password: String) async throws -> FirebaseAuthResult

    /// Get the current user's fresh ID token (auto-refreshes if expired).
    func getIDToken() async throws -> String

    /// Get the current user's fresh ID token with expiry info.
    func getIDTokenWithExpiry() async throws -> (token: String, expiresAt: Date?)

    /// Change the current user's password. Reauthenticates with the current
    /// password first (Firebase requires a recent login for sensitive operations).
    func updatePassword(currentPassword: String, newPassword: String) async throws

    /// Sign out from Firebase Auth.
    func signOut() throws

    /// Whether a Firebase user is currently signed in.
    var isSignedIn: Bool { get }

    /// Current Firebase user's UID.
    var currentUserUID: String? { get }
}

// MARK: - FirebaseAuthResult

struct FirebaseAuthResult: Sendable {
    let idToken: String
    let uid: String
    let email: String?
    let expiresAt: Date?
}

// MARK: - FirebaseAuthService

final class FirebaseAuthService: FirebaseAuthServiceProtocol, @unchecked Sendable {

    static let shared = FirebaseAuthService()

    private init() {}

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws -> FirebaseAuthResult {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let idToken = try await result.user.getIDToken()
        let expiresAt = extractExpiryFromToken(idToken)

        return FirebaseAuthResult(
            idToken: idToken,
            uid: result.user.uid,
            email: result.user.email,
            expiresAt: expiresAt
        )
    }

    // MARK: - Create Account

    func createAccount(email: String, password: String) async throws -> FirebaseAuthResult {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let idToken = try await result.user.getIDToken()
        let expiresAt = extractExpiryFromToken(idToken)

        return FirebaseAuthResult(
            idToken: idToken,
            uid: result.user.uid,
            email: result.user.email,
            expiresAt: expiresAt
        )
    }

    // MARK: - Get ID Token

    /// Returns a fresh ID token. Firebase SDK auto-refreshes if the token is expired.
    func getIDToken() async throws -> String {
        let (token, _) = try await getIDTokenWithExpiry()
        return token
    }

    /// Returns a fresh ID token with expiry information.
    func getIDTokenWithExpiry() async throws -> (token: String, expiresAt: Date?) {
        guard let user = Auth.auth().currentUser else {
            throw FirebaseAuthError.notSignedIn
        }
        let idToken = try await user.getIDToken()
        let expiresAt = extractExpiryFromToken(idToken)
        return (idToken, expiresAt)
    }

    // MARK: - Change Password

    func updatePassword(currentPassword: String, newPassword: String) async throws {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            throw FirebaseAuthError.notSignedIn
        }
        // Reauthenticate first — Firebase requires a recent credential for password changes.
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        try await user.reauthenticate(with: credential)
        try await user.updatePassword(to: newPassword)
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: - State

    var isSignedIn: Bool {
        Auth.auth().currentUser != nil
    }

    var currentUserUID: String? {
        Auth.auth().currentUser?.uid
    }
}

// MARK: - FirebaseAuthError

enum FirebaseAuthError: LocalizedError {
    case notSignedIn
    case tokenRetrievalFailed

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "No Firebase user is currently signed in."
        case .tokenRetrievalFailed:
            return "Failed to retrieve Firebase ID token."
        }
    }
}

// MARK: - Private Helpers

private extension FirebaseAuthService {
    /// Decodes a JWT token and extracts the expiry date from the `exp` claim.
    func extractExpiryFromToken(_ token: String) -> Date? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }

        let payload = parts[1]
        var base64 = String(payload)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else {
            return nil
        }

        return Date(timeIntervalSince1970: exp)
    }
}
