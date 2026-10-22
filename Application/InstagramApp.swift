//
//  InstagramApp.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 20/7/26.
//

import SwiftUI
import FirebaseCore

@main
struct InstagramApp: App {

    init() {
        // Configure Firebase (must be called before any Firebase service is used)
        FirebaseApp.configure()

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

        // Session restoration and scheme-aware auto-login for development/testing.
        if FirebaseAuthService.shared.isSignedIn && SessionStore.shared.currentUser != nil {
            AppRouter.shared.isAuthenticated = true
        } else {
            performFirebaseAutoLogin()
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
                .withOfflineBanner() // Persistent Instagram-style top connectivity banner.
        }
    }

    // MARK: - Firebase Auto-Login

    /// In Firebase mode, automatically authenticates or registers the primary test user (Tom The Cat)
    /// and triggers background data synchronization with Cloud Firestore.
    private func performFirebaseAutoLogin() {
        Task { @MainActor in
            let authRepo = FirebaseAuthRepository()
            let testEmail = "tom@example.com"
            let testPassword = "password123"
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
                        name: "Tom The Cat",
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
}
