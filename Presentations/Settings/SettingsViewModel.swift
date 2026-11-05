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
    private let biometricAuthUseCase: BiometricAuthUseCaseProtocol
    private let keychainManager: KeychainManagerProtocol
    private let webSocketConnectionManager: WebSocketConnectionManagerProtocol

    // MARK: - Init

    init(
        authRepository: AuthRepositoryProtocol,
        userRepository: UserRepositoryProtocol,
        biometricAuthUseCase: BiometricAuthUseCaseProtocol,
        keychainManager: KeychainManagerProtocol,
        webSocketConnectionManager: WebSocketConnectionManagerProtocol
    ) {
        self.authRepository = authRepository
        self.userRepository = userRepository
        self.biometricAuthUseCase = biometricAuthUseCase
        self.keychainManager = keychainManager
        self.webSocketConnectionManager = webSocketConnectionManager
        self.isBiometricEnabled = biometricAuthUseCase.isBiometricEnabled
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
        try? await authRepository.logout()
        SessionStore.shared.clear()
        AppRouter.shared.isAuthenticated = false
        AppRouter.shared.reset()

        // Disconnect WebSocket
        webSocketConnectionManager.handleAuthStateChange(isAuthenticated: false)

        isLoggingOut = false
    }

    func togglePrivateAccount() async {
        // TODO: Implement togglePrivateAccount logic from scratch
    }

    func setBiometricEnabled(_ enabled: Bool) async {
        isBiometricEnabled = enabled
        biometricAuthUseCase.setBiometricEnabled(enabled)

        // Sync with backend
        do {
            let patch = UserSettingsPatch(language: nil, biometricEnabled: enabled, pushEnabled: nil, darkMode: nil)
            _ = try await userRepository.updateSettings(patch)
        } catch {
            // Revert on failure
            isBiometricEnabled = !enabled
            biometricAuthUseCase.setBiometricEnabled(!enabled)
        }
    }

    func clearCache() {
        ImagePipelineManager.clear()
        ToastManager.shared.success(L10n.Settings.cacheCleared)
    }
}
