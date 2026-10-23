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
        let appConfig = AppConfig.shared
        if appConfig.isFirebaseAPI {
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
}
