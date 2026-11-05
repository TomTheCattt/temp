//
//  InstagramApp.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 20/7/26.
//

import SwiftUI
import FirebaseCore
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
        let appConfig = AppConfig.shared
        // Force live backend during tests to avoid Firebase/GoogleUtilities initialization
        let useFirebase = appConfig.isFirebaseAPI && !isRunningTests

        if useFirebase {
            // Configure Firebase (must be called before any Firebase service is used)
            FirebaseApp.configure()

            // Session restoration and scheme-aware auto-login for development/testing.
            if FirebaseAuthService.shared.isSignedIn && SessionStore.shared.currentUser != nil {
                AppRouter.shared.isAuthenticated = true
            } else {
                #if DEBUG
                performFirebaseAutoLogin()
                #endif
            }
        } else {
            // Auto login when the application is not using FirebaseAPI
            // Check if user is already authenticated (tokens in keychain)
            restoreAuthenticationState()
        }

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
            _ = try await messageRepository.fetchMessages(conversationId: conversationId, page: 1, perPage: 50)
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

    // MARK: - Firebase Auto-Login

    #if DEBUG
    /// In Firebase mode, automatically authenticates or registers the primary test user (Tom The Cat)
    /// and triggers background data synchronization with Cloud Firestore for local testing.
    private func performFirebaseAutoLogin() {
        Task { @MainActor in
            let authRepo = FirebaseAuthRepository()
            let testEmail = AppConstants.TestAccount.email
            let testPassword = AppConstants.TestAccount.password
            let testName = AppConstants.TestAccount.fullName
            do {
                AppLogger.auth.info("Attempting Firebase login for test user: \(testEmail)")
                let session = try await authRepo.login(
                    email: testEmail,
                    password: testPassword
                )
                SessionStore.shared.setSession(user: session.user)
                AppRouter.shared.isAuthenticated = true
                AppLogger.auth.info("Firebase login succeeded for uid: \(session.user.id)")
            } catch {
                AppLogger.auth.notice("Firebase login failed (\(error.localizedDescription)). Attempting auto-registration...")
                do {
                    let session = try await authRepo.register(
                        name: testName,
                        email: testEmail,
                        password: testPassword,
                        phone: "+84901234567"
                    )
                    SessionStore.shared.setSession(user: session.user)
                    AppRouter.shared.isAuthenticated = true
                    AppLogger.auth.info("Firebase auto-registration succeeded for uid: \(session.user.id)")
                } catch let regError {
                    AppLogger.auth.error("Firebase auto-registration failed (\(regError.localizedDescription)).")
                }
            }
        }
    }
    #endif

    /// Restores authentication state on app launch for non-Firebase backends.
    /// Checks if valid tokens exist in Keychain and connects WebSocket if authenticated.
    private func restoreAuthenticationState() {
        Task { @MainActor in
            // Resolve AuthManager to check authentication state
            let authManager = DIContainer.shared.resolve(AuthManagerProtocol.self)

            if authManager.isAuthenticated {
                AppLogger.auth.info("Restored authentication state from Keychain")
                AppRouter.shared.isAuthenticated = true

                // Connect WebSocket
                let wsManager = DIContainer.shared.resolve(WebSocketConnectionManagerProtocol.self)
                wsManager.handleAuthStateChange(isAuthenticated: true)
            } else {
                AppLogger.auth.info("No valid authentication state found")
            }
        }
    }
}
