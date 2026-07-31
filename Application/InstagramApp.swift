//
//  InstagramApp.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 20/7/26.
//

import SwiftUI

@main
struct InstagramApp: App {

    init() {
        // Initialize DI container (triggers all assembly registrations)
        _ = DIContainer.shared

        // Configure image pipeline
        ImagePipelineManager.configure()

        // Auto-login in mock API mode for development/testing
        if AppConfig.shared.isMockAPI {
            AppRouter.shared.isAuthenticated = true
        }
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .withBaseFeatures()
                .withAppTheme()
        }
    }
}
