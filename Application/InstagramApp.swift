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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
