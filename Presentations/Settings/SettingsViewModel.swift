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

    /// Guards against re-entrant network calls / feedback loops when toggles
    /// are updated programmatically (e.g. reverting after a failed API call).
    private var isApplyingRemoteChange = false

    /// Data usage.
    var isHighQualityUploads = true
    var isCellularDataEnabled = true

    private(set) var isLoggingOut = false
    private(set) var isLoading = false

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
        isLoading = true

        // Load private-account flag from the profile.
        do {
            let user = try await userRepository.fetchCurrentUser()
            isApplyingRemoteChange = true
            isPrivateAccount = user.isPrivate
            isApplyingRemoteChange = false
        } catch {
            // Keep default.
        }

        // Load notification + data-usage preferences from the settings endpoint.
        do {
            let settings = try await userRepository.fetchSettings()
            applySettings(settings)
        } catch {
            // Keep defaults.
        }

        isLoading = false
    }

    /// Applies a server settings object to the local toggles without triggering
    /// the view's `.onChange` persistence handlers.
    private func applySettings(_ settings: UserSettings) {
        isApplyingRemoteChange = true
        isPushEnabled = settings.pushEnabled
        isLikeNotificationEnabled = settings.likeNotifications
        isCommentNotificationEnabled = settings.commentNotifications
        isFollowNotificationEnabled = settings.followNotifications
        isDirectMessageNotificationEnabled = settings.directMessageNotifications
        isActivityStatusVisible = settings.activityStatusVisible
        isHighQualityUploads = settings.highQualityUploads
        isCellularDataEnabled = settings.cellularDataEnabled
        isApplyingRemoteChange = false
    }

    /// Snapshot of the current toggle state as a settings entity.
    private var currentSettings: UserSettings {
        UserSettings(
            pushEnabled: isPushEnabled,
            likeNotifications: isLikeNotificationEnabled,
            commentNotifications: isCommentNotificationEnabled,
            followNotifications: isFollowNotificationEnabled,
            directMessageNotifications: isDirectMessageNotificationEnabled,
            activityStatusVisible: isActivityStatusVisible,
            highQualityUploads: isHighQualityUploads,
            cellularDataEnabled: isCellularDataEnabled
        )
    }

    /// Persists the current toggle state to the backend.
    /// Called from the view's `.onChange` handlers; reverts to the server value on failure.
    func persistSettings() async {
        guard !isApplyingRemoteChange else { return }

        do {
            let updated = try await userRepository.updateSettings(.full(currentSettings))
            // Reconcile with the authoritative server response.
            applySettings(updated)
        } catch {
            // Revert to the last known-good server state.
            do {
                let server = try await userRepository.fetchSettings()
                applySettings(server)
            } catch {
                // If reload also fails, leave the UI as-is.
            }
            ToastManager.shared.error(error.userMessage)
        }
    }

    func logout() async {
        isLoggingOut = true
        HUDManager.shared.showLoading(L10n.HUD.loggingOut)

        do {
            try await authRepository.logout()
        } catch {
            // Force logout locally even if the API call fails — this is best-effort.
        }

        // Always clear local session and reset navigation.
        SessionStore.shared.clear()
        AppRouter.shared.isAuthenticated = false
        AppRouter.shared.reset()

        HUDManager.shared.dismiss()
        isLoggingOut = false
    }

    /// Persists the private-account change to the backend.
    /// Called from the view's `.onChange` after the toggle flips `isPrivateAccount`.
    /// Reverts the toggle if the API call fails.
    func togglePrivateAccount() async {
        guard !isApplyingRemoteChange else { return }

        let desired = isPrivateAccount
        do {
            _ = try await userRepository.setPrivateAccount(desired)
        } catch {
            // Revert the toggle without re-triggering this handler.
            isApplyingRemoteChange = true
            isPrivateAccount = !desired
            isApplyingRemoteChange = false
            ToastManager.shared.error(error.userMessage)
        }
    }

    /// Enables/disables biometric login.
    /// Enabling requires a successful biometric check; the preference is stored in the Keychain.
    func setBiometricEnabled(_ enabled: Bool) async {
        guard !isApplyingRemoteChange else { return }

        if enabled {
            guard biometricAuthenticator.canAuthenticate(policy: .biometricsOrDevicePasscode) else {
                revertBiometric(to: false)
                ToastManager.shared.warning(L10n.Settings.biometricUnavailable)
                return
            }

            do {
                let success = try await biometricAuthenticator.authenticate(
                    reason: L10n.Settings.biometricReason,
                    policy: .biometricsOrDevicePasscode
                )
                if success {
                    keychainManager.set(value: "true", key: KeychainKeys.biometricEnabled)
                } else {
                    revertBiometric(to: false)
                }
            } catch {
                revertBiometric(to: false)
            }
        } else {
            keychainManager.delete(key: KeychainKeys.biometricEnabled)
        }
    }

    private func revertBiometric(to value: Bool) {
        isApplyingRemoteChange = true
        isBiometricEnabled = value
        isApplyingRemoteChange = false
    }

    /// Clears the on-disk and in-memory image cache.
    func clearCache() {
        ImagePipelineManager.clear()
        ToastManager.shared.success(L10n.Settings.cacheCleared)
    }
}
