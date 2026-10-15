//
//  SessionStore.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import Foundation
import Observation

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
@Observable
final class SessionStore: SessionStoreProtocol {

    static let shared = SessionStore()

    /// The current authenticated user's ID.
    private(set) var currentUserId: String = ""

    /// The current authenticated user's full profile.
    private(set) var currentUser: User?

    private let sessionUserKey = "com.instagram.current_session_user"

    private init() {
        _ = restoreSession()
    }

    /// Populate session after successful authentication and persist to local storage.
    func setSession(user: User) {
        currentUserId = user.id
        currentUser = user

        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: sessionUserKey)
        }
    }

    /// Restore session from local storage on app launch.
    @discardableResult
    func restoreSession() -> User? {
        guard let data = UserDefaults.standard.data(forKey: sessionUserKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return nil
        }
        currentUserId = user.id
        currentUser = user
        return user
    }

    /// Clear session on logout.
    func clear() {
        currentUserId = ""
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: sessionUserKey)
    }
}
