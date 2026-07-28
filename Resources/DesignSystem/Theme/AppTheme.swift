//
//  AppTheme.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - AppThemeMode

enum AppThemeMode: String, CaseIterable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

// MARK: - ThemeManager

/// Centralized theme state manager.
@MainActor
@Observable
final class ThemeManager {

    static let shared = ThemeManager()

    /// Current theme mode selected by user.
    var themeMode: AppThemeMode {
        didSet {
            UserDefaults.standard.set(themeMode.rawValue, forKey: "app_theme_mode")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "app_theme_mode") ?? "system"
        self.themeMode = AppThemeMode(rawValue: saved) ?? .system
    }

    /// The preferred ColorScheme, nil means follow system.
    var preferredColorScheme: ColorScheme? {
        themeMode.colorScheme
    }
}

// MARK: - Theme ViewModifier

/// Apply this at the root of the app to enforce the selected theme.
struct AppThemeModifier: ViewModifier {

    @State private var themeManager = ThemeManager.shared

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.preferredColorScheme)
    }
}

extension View {
    /// Apply the app's theme preference (dark/light/system).
    func withAppTheme() -> some View {
        modifier(AppThemeModifier())
    }
}
