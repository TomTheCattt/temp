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
}

// MARK: - FirebaseAuthService

final class FirebaseAuthService: FirebaseAuthServiceProtocol, @unchecked Sendable {

    static let shared = FirebaseAuthService()

    private init() {}

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws -> FirebaseAuthResult {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let idToken = try await result.user.getIDToken()

        return FirebaseAuthResult(
            idToken: idToken,
            uid: result.user.uid,
            email: result.user.email
        )
    }

    // MARK: - Create Account

    func createAccount(email: String, password: String) async throws -> FirebaseAuthResult {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let idToken = try await result.user.getIDToken()

        return FirebaseAuthResult(
            idToken: idToken,
            uid: result.user.uid,
            email: result.user.email
        )
    }

    // MARK: - Get ID Token

    /// Returns a fresh ID token. Firebase SDK auto-refreshes if the token is expired.
    func getIDToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw FirebaseAuthError.notSignedIn
        }
        return try await user.getIDToken()
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
