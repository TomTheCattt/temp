//
//  SettingsViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - SettingsViewModel

@MainActor
@Observable
final class SettingsViewModel {

    // MARK: - State

    /// Notification preferences.
    var isPushEnabled = true
    var isLikeNotificationEnabled = true
    var isCommentNotificationEnabled = true
    var isFollowNotificationEnabled = true
    var isDirectMessageNotificationEnabled = true

    /// Privacy settings.
    var isPrivateAccount = false
    var isActivityStatusVisible = true

    /// Security.
    var isBiometricEnabled = false

    /// Data usage.
    var isHighQualityUploads = true
    var isCellularDataEnabled = true

    private(set) var isLoggingOut = false
    private(set) var isLoading = false

    // MARK: - Dependencies

    private let authRepository: AuthRepositoryProtocol
    private let userRepository: UserRepositoryProtocol

    // MARK: - Init

    init(
        authRepository: AuthRepositoryProtocol,
        userRepository: UserRepositoryProtocol
    ) {
        self.authRepository = authRepository
        self.userRepository = userRepository
    }

    // MARK: - Actions

    func loadSettings() async {
        isLoading = true

        do {
            let user = try await userRepository.fetchCurrentUser()
            isPrivateAccount = user.isPrivate
        } catch {
            // Use defaults
        }

        isLoading = false
    }

    func logout() async {
        isLoggingOut = true

        do {
            try await authRepository.logout()
            SessionStore.shared.clear()
            AppRouter.shared.isAuthenticated = false
            AppRouter.shared.reset()
        } catch {
            // Force logout locally even if API fails
            SessionStore.shared.clear()
            AppRouter.shared.isAuthenticated = false
            AppRouter.shared.reset()
        }

        isLoggingOut = false
    }

    func togglePrivateAccount() async {
        // TODO: call API to update privacy setting
        isPrivateAccount.toggle()
    }
}
