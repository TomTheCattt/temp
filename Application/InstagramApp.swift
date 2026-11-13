//
//  InstagramApp.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 20/7/26.
//

import SwiftUI
import UserNotifications
import Combine

// Global cancellables storage for app-level subscriptions
private var appCancellables = Set<AnyCancellable>()

// Detect test environment at process launch (before test bundle injection)
private var isRunningTests: Bool {
    let env = ProcessInfo.processInfo.environment
    if env["XCTestConfigurationFilePath"] != nil { return true }
    if env["XCTestSessionIdentifier"] != nil { return true }
    if ProcessInfo.processInfo.arguments.contains(where: { $0.hasPrefix("-XCTest") }) { return true }
    if NSClassFromString("XCTest") != nil { return true }
    return false
}

@main
struct InstagramApp: App {

    init() {
        // Auto login when the application is not using FirebaseAPI
        // Check if user is already authenticated (tokens in keychain)
        restoreAuthenticationState()

        // Initialize DI container (triggers all assembly registrations)
        _ = DIContainer.shared

        // Configure image pipeline
        ImagePipelineManager.configure()

        // Register for VoIP pushes early to handle background incoming calls
        VoIPPushService.shared.registerForVoIPPushes()

        // Start app-wide internet connectivity monitoring (drives offline/online toasts).
        Task { @MainActor in
            NetworkMonitor.shared.start()
        }

        // Initialize Push Notifications
        setupPushNotifications()
    }

    private func setupPushNotifications() {
        Task { @MainActor in
            // Set up notification center delegate
            UNUserNotificationCenter.current().delegate = PushNotificationService.shared

            // Request authorization
            let granted = await PushNotificationService.shared.requestAuthorization()
            if granted {
                // Register for remote notifications (APNs)
                PushNotificationService.shared.registerForRemoteNotifications()
            }

            // Initialize notification router (subscribes to tapped notifications)
            _ = NotificationRouter.shared

            // Subscribe to received notifications to sync messages in background
            subscribeToBackgroundMessages()
        }
    }

    private func subscribeToBackgroundMessages() {
        // When a message push is received in background/foreground, trigger message sync
        PushNotificationService.shared.notificationReceived
            .receive(on: RunLoop.main)
            .sink { payload in
                guard payload.type == .message, let conversationId = payload.conversationId else { return }
                Task {
                    // Trigger message sync for this conversation
                    await syncMessagesForConversation(conversationId)
                }
            }
            .store(in: &appCancellables)
    }

    @MainActor
    private func syncMessagesForConversation(_ conversationId: String) async {
        do {
            let messageRepository = DIContainer.shared.resolve(MessageRepositoryProtocol.self)
            _ = try await messageRepository.fetchMessages(conversationId: conversationId, cursor: nil, perPage: 50)
            // Also update unread badge
            if let count = try? await messageRepository.getUnreadConversationsCount() {
                AppState.shared.setUnreadChatCount(count)
                try await UNUserNotificationCenter.current().setBadgeCount(count)
            }
        } catch {
            AppLogger.general.error("Failed to sync messages from push: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            // RootContainerView hosts SplashView and overlays global blocking
            // screens (maintenance / force-update) driven by AppState.
            RootContainerView()
                .withBaseFeatures()
                .withAppTheme()
                .withToast() // Single global toast host for the whole app.
                .withHUD() // Single global action HUD host for the whole app.
                .withOfflineBanner() // Persistent Instagram-style top connectivity banner.
        }
    }

    /// Restores authentication state on app launch for non-Firebase backends.
    /// Checks if valid tokens exist in Keychain, validates with backend, fetches fresh profile, and connects WebSocket if authenticated.
    private func restoreAuthenticationState() {
        Task { @MainActor in
            // Resolve AuthManager to check authentication state
            let authManager = DIContainer.shared.resolve(AuthManagerProtocol.self)

            if authManager.isAuthenticated {
                AppLogger.auth.info("Restored authentication state from Keychain, validating with backend...")

                do {
                    // Validate token with backend and fetch fresh user profile
                    let user = try await authManager.validateTokenAndFetchProfile()
                    if let user = user {
                        AppLogger.auth.info("Token validated successfully for user: \(user.username)")
                        AppRouter.shared.isAuthenticated = true

                        // Connect WebSocket
                        let wsManager = DIContainer.shared.resolve(WebSocketConnectionManagerProtocol.self)
                        wsManager.handleAuthStateChange(isAuthenticated: true)

                        // Register device token for push notifications
                        await registerDeviceTokenIfNeeded()

                        // Initialize offline message queue (auto-processes on network changes)
                        initializeOfflineMessageQueue()

                        // Fetch initial unread counts
                        await fetchInitialUnreadCounts()
                    } else {
                        // Token validation failed - logout
                        AppLogger.auth.notice("Token validation returned no user, logging out")
                        authManager.logout(reason: .sessionExpired)
                    }
                } catch {
                    // Token validation or refresh failed - logout
                    AppLogger.auth.error("Token validation failed: \(error.localizedDescription)")
                    authManager.logout(reason: .sessionExpired)
                }
            } else {
                AppLogger.auth.info("No valid authentication state found")
            }
        }
    }

    /// Register device token with backend for push notifications.
    private func registerDeviceTokenIfNeeded() async {
        // Get APNs device token and register with backend
        if let deviceToken = PushNotificationService.shared.deviceToken {
            do {
                try await DIContainer.shared.resolve(UserRepositoryProtocol.self).addDeviceToken(
                    token: deviceToken,
                    platform: "ios"
                )
                AppLogger.general.info("Device token registered with backend")
            } catch {
                AppLogger.general.error("Failed to register device token: \(error.localizedDescription)")
            }
        }
    }

    /// Ensure offline message queue is initialized (auto-starts on network changes).
    private func initializeOfflineMessageQueue() {
        // OfflineMessageQueue.shared is a singleton that auto-initializes on first access
        // and observes network changes via observeNetwork()
        _ = OfflineMessageQueue.shared
    }

    /// Fetch initial unread counts for chat and notifications.
    private func fetchInitialUnreadCounts() async {
        do {
            // Fetch unread notification count
            let notificationCount = try await DIContainer.shared.resolve(FetchUnreadNotificationCountUseCaseProtocol.self).execute()
            AppState.shared.setUnreadNotificationCount(notificationCount)

            // Fetch unread chat count
            let chatRepository = DIContainer.shared.resolve(MessageRepositoryProtocol.self)
            let chatCount = try await chatRepository.getUnreadConversationsCount()
            AppState.shared.setUnreadChatCount(chatCount)

            // Set badge count
            let totalUnread = notificationCount + chatCount
            try await UNUserNotificationCenter.current().setBadgeCount(totalUnread)
        } catch {
            AppLogger.general.error("Failed to fetch initial unread counts: \(error.localizedDescription)")
        }
    }
}
