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

    var isPushEnabled = true
    var isLikeNotificationEnabled = true
    var isCommentNotificationEnabled = true
    var isFollowNotificationEnabled = true
    var isDirectMessageNotificationEnabled = true

    var isPrivateAccount = false
    var isActivityStatusVisible = true

    var isBiometricEnabled = false

    var isHighQualityUploads = true
    var isCellularDataEnabled = true

    var isLoggingOut = false
    var isLoading = false

    // MARK: - Dependencies

    private let authRepository: AuthRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let biometricAuthenticator: BiometricAuthenticating
    private let keychainManager: KeychainManagerProtocol

    // MARK: - Init

    init(
        authRepository: AuthRepositoryProtocol,
        userRepository: UserRepositoryProtocol,
        biometricAuthenticator: BiometricAuthenticating,
        keychainManager: KeychainManagerProtocol
    ) {
        self.authRepository = authRepository
        self.userRepository = userRepository
        self.biometricAuthenticator = biometricAuthenticator
        self.keychainManager = keychainManager
        self.isBiometricEnabled = keychainManager.get(key: KeychainKeys.biometricEnabled) == "true"
    }

    // MARK: - Actions

    func loadSettings() async {
        // TODO: Implement loadSettings logic from scratch
    }

    func persistSettings() async {
        // TODO: Implement persistSettings logic from scratch
    }

    func logout() async {
        isLoggingOut = true
        // TODO: Implement logout logic from scratch
        SessionStore.shared.clear()
        AppRouter.shared.isAuthenticated = false
        AppRouter.shared.reset()
        isLoggingOut = false
    }

    func togglePrivateAccount() async {
        // TODO: Implement togglePrivateAccount logic from scratch
    }

    func setBiometricEnabled(_ enabled: Bool) async {
        isBiometricEnabled = enabled
        // TODO: Implement biometric settings logic from scratch
    }

    func clearCache() {
        ImagePipelineManager.clear()
        ToastManager.shared.success(L10n.Settings.cacheCleared)
    }
}
