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
        if AppConfig.shared.isFirebaseAPI {
            if FirebaseAuthService.shared.isSignedIn && SessionStore.shared.currentUser != nil {
                AppRouter.shared.isAuthenticated = true
                Task {
                    await FirebaseDataSeeder.shared.seedIfNeeded()
                }
            } else {
                performFirebaseAutoLogin()
            }
        } else if AppConfig.shared.isMockAPI {
            if SessionStore.shared.currentUser != nil {
                AppRouter.shared.isAuthenticated = true
            } else {
                performMockAutoLogin()
            }
        } else {
            if SessionStore.shared.currentUser != nil {
                AppRouter.shared.isAuthenticated = true
            }
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
        }
    }

    // MARK: - Mock Auto-Login

    /// Simulates the production login flow using MockAuthDataSource.
    /// This ensures SessionStore is populated identically to a real login.
    private func performMockAutoLogin() {
        let mockAuth = MockAuthDataSource()
        Task { @MainActor in
            do {
                let session = try await mockAuth.login(
                    email: MockData.testEmail,
                    password: MockData.testPassword
                )
                SessionStore.shared.setSession(user: session.user)
                AppRouter.shared.isAuthenticated = true
            } catch {
                // Fallback: still allow access in mock mode
                AppRouter.shared.isAuthenticated = true
            }
        }
    }

    // MARK: - Firebase Auto-Login

    /// In Firebase mode, automatically authenticates or registers the primary test user (Tom The Cat)
    /// and triggers background data synchronization with Cloud Firestore.
    private func performFirebaseAutoLogin() {
        Task { @MainActor in
            let authRepo = FirebaseAuthRepository()
            do {
                AppLogger.auth.info("Attempting Firebase login for test user: \(MockData.testEmail)")
                let session = try await authRepo.login(
                    email: MockData.testEmail,
                    password: MockData.testPassword
                )
                SessionStore.shared.setSession(user: session.user)
                AppRouter.shared.isAuthenticated = true
                AppLogger.auth.info("Firebase login succeeded for uid: \(session.user.id)")
            } catch {
                AppLogger.auth.notice("Firebase login failed (\(error.localizedDescription)). Attempting auto-registration...")
                do {
                    let session = try await authRepo.register(
                        name: MockData.currentUser.fullName,
                        email: MockData.testEmail,
                        password: MockData.testPassword,
                        phone: MockData.currentUser.phone ?? ""
                    )
                    SessionStore.shared.setSession(user: session.user)
                    AppRouter.shared.isAuthenticated = true
                    AppLogger.auth.info("Firebase auto-registration succeeded for uid: \(session.user.id)")
                } catch let regError {
                    AppLogger.auth.error("Firebase auto-registration failed (\(regError.localizedDescription)). Using local session fallback.")
                    SessionStore.shared.setSession(user: MockData.currentUser)
                    AppRouter.shared.isAuthenticated = true
                }
            }

            // Background cloud data seeding
            Task {
                await FirebaseDataSeeder.shared.seedIfNeeded()
            }
        }
    }
}
