//
//  SessionStore.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import Foundation

// MARK: - SessionStoreProtocol

@MainActor
protocol SessionStoreProtocol: AnyObject {
    var currentUserId: String { get }
    var currentUser: User? { get }
    func setSession(user: User)
    func clear()
}

// MARK: - SessionStore

/// Stores the current authenticated user's session.
/// Set after login/app launch; read anywhere that needs to identify "me" or access current user data.
@MainActor
final class SessionStore: SessionStoreProtocol {

    static let shared = SessionStore()

    /// The current authenticated user's ID.
    private(set) var currentUserId: String = ""

    /// The current authenticated user's full profile.
    private(set) var currentUser: User?

    private init() {}

    /// Populate session after successful authentication.
    func setSession(user: User) {
        currentUserId = user.id
        currentUser = user
    }

    /// Clear session on logout.
    func clear() {
        currentUserId = ""
        currentUser = nil
    }
}
