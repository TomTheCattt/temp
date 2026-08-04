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

        // Auto-login in mock API mode for development/testing.
        // Uses the same flow as production: authenticate → populate SessionStore → set router state.
        if AppConfig.shared.isMockAPI {
            performMockAutoLogin()
        }
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .withBaseFeatures()
                .withAppTheme()
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
}
