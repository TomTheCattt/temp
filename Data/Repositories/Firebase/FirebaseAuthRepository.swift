//
//  FirebaseAuthRepository.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation
import FirebaseAuth

// MARK: - FirebaseAuthRepository

/// Production-ready Firebase Auth repository implementing `AuthRepositoryProtocol`.
/// Integrates Firebase Authentication with Firestore profile persistence and `SessionStore`.
final class FirebaseAuthRepository: AuthRepositoryProtocol, @unchecked Sendable {

    private let firebaseAuth: FirebaseAuthServiceProtocol
    private let userDataSource: FirebaseUserDataSource
    private let logger = AppLogger.auth

    init(
        firebaseAuth: FirebaseAuthServiceProtocol = FirebaseAuthService.shared,
        userDataSource: FirebaseUserDataSource = FirebaseUserDataSource.shared
    ) {
        self.firebaseAuth = firebaseAuth
        self.userDataSource = userDataSource
    }

    // MARK: - Login

    func login(email: String, password: String) async throws -> AuthSession {
        // Step 1: Sign in via Firebase Auth
        let authResult = try await firebaseAuth.signIn(email: email, password: password)

        // Step 2: Fetch user profile from Firestore or fallback to constructing initial profile
        let user: User
        do {
            user = try await userDataSource.fetchUser(id: authResult.uid)
        } catch {
            let derivedUsername = email.components(separatedBy: "@").first?.lowercased() ?? "user"
            let fallbackUser = User(
                id: authResult.uid,
                username: derivedUsername,
                fullName: derivedUsername.capitalized,
                email: email,
                phone: nil,
                avatarURL: nil,
                bio: nil,
                website: nil,
                isVerified: false,
                isPrivate: false,
                followersCount: 0,
                followingCount: 0,
                postsCount: 0,
                createdAt: .now,
                isFollowing: false,
                isFollowedBy: false,
                isBlocked: false
            )
            try? await userDataSource.saveUser(fallbackUser)
            user = fallbackUser
        }

        // Step 3: Populate local SessionStore
        await MainActor.run {
            SessionStore.shared.setSession(user: user)
        }

        return AuthSession(
            accessToken: authResult.idToken,
            refreshToken: "",
            user: user,
            expiresAt: nil
        )
    }

    // MARK: - Register

    func register(name: String, email: String, password: String, phone: String) async throws -> AuthSession {
        // Step 1: Create account via Firebase Auth
        let authResult = try await firebaseAuth.createAccount(email: email, password: password)

        // Step 2: Create user profile document in Firestore
        let derivedUsername = email.components(separatedBy: "@").first?.lowercased() ?? "user"
        let newUser = User(
            id: authResult.uid,
            username: derivedUsername,
            fullName: name,
            email: email,
            phone: phone.isEmpty ? nil : phone,
            avatarURL: nil,
            bio: nil,
            website: nil,
            isVerified: false,
            isPrivate: false,
            followersCount: 0,
            followingCount: 0,
            postsCount: 0,
            createdAt: .now,
            isFollowing: false,
            isFollowedBy: false,
            isBlocked: false
        )

        try await userDataSource.saveUser(newUser)

        // Step 3: Populate local SessionStore
        await MainActor.run {
            SessionStore.shared.setSession(user: newUser)
        }

        return AuthSession(
            accessToken: authResult.idToken,
            refreshToken: "",
            user: newUser,
            expiresAt: nil
        )
    }

    // MARK: - Refresh Token

    func refreshToken() async throws -> AuthSession {
        let idToken = try await firebaseAuth.getIDToken()
        let currentUser: User
        if let sessionUser = await MainActor.run(body: { SessionStore.shared.currentUser }) {
            currentUser = sessionUser
        } else if let user = try? await userDataSource.fetchCurrentUser() {
            currentUser = user
        } else {
            currentUser = User.empty
        }

        return AuthSession(
            accessToken: idToken,
            refreshToken: "",
            user: currentUser,
            expiresAt: nil
        )
    }

    // MARK: - Logout

    func logout() async throws {
        try firebaseAuth.signOut()
        await MainActor.run {
            SessionStore.shared.clear()
        }
    }

    // MARK: - Password Management

    func forgotPassword(phoneNumber: String) async throws {
        if phoneNumber.contains("@") {
            try await Auth.auth().sendPasswordReset(withEmail: phoneNumber)
        } else if let userEmail = Auth.auth().currentUser?.email {
            try await Auth.auth().sendPasswordReset(withEmail: userEmail)
        } else {
            logger.info("Password reset requested for phone or placeholder: \(phoneNumber)")
        }
    }

    func resetPassword(token: String, newPassword: String) async throws {
        try await Auth.auth().confirmPasswordReset(withCode: token, newPassword: newPassword)
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        try await firebaseAuth.updatePassword(currentPassword: currentPassword, newPassword: newPassword)
    }

    // MARK: - Email Verification

    func verifyEmail(token: String) async throws {
        if !token.isEmpty {
            try? await Auth.auth().applyActionCode(token)
        }

        guard let user = Auth.auth().currentUser else {
            throw FirebaseAuthError.notSignedIn
        }

        try await user.reload()
        guard user.isEmailVerified else {
            throw AuthError.invalidOTP
        }
    }

    func resendVerification(email: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw FirebaseAuthError.notSignedIn
        }
        try await user.sendEmailVerification()
    }
}
