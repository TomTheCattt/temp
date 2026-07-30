//
//  AppEnvironment.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 20/7/26.
//

import Foundation

import Foundation

// MARK: - AppEnvironment

enum AppEnvironment: String {
    case development  = "dev"
    case staging      = "staging"
    case production   = "prod"

    // Reads from process environment (scheme) first, then Info.plist key APP_ENVIRONMENT.
    static var current: AppEnvironment {
        // Priority 1: Scheme environment variable
        if let envValue = ProcessInfo.processInfo.environment["APP_ENVIRONMENT"],
           let env = AppEnvironment(rawValue: envValue) {
            return env
        }
        // Priority 2: Info.plist
        let raw = Bundle.main.infoDictionary?["APP_ENVIRONMENT"] as? String ?? "prod"
        return AppEnvironment(rawValue: raw) ?? .production
    }

    var defaultBaseURL: String {
        switch self {
        case .development:  return "https://dev-api.example.com"
        case .staging:      return "https://staging-api.example.com"
        case .production:   return "https://api.example.com"
        }
    }

    var isDebugLoggingEnabled: Bool {
        self != .production
    }

    var displayName: String {
        switch self {
        case .development:  return "DEV"
        case .staging:      return "STAGING"
        case .production:   return ""
        }
    }
}

// MARK: - APIMode

enum APIMode: String {
    case live
    case mock

    /// Resolves API mode from:
    /// 1. Process environment variable (set via Xcode scheme) — highest priority
    /// 2. Info.plist key (set via xcconfig / build settings)
    /// 3. Defaults to `.live`
    static var current: APIMode {
        // Priority 1: Scheme environment variable
        if let envValue = ProcessInfo.processInfo.environment["API_MODE"]?.lowercased(),
           let mode = APIMode(rawValue: envValue) {
            return mode
        }
        // Priority 2: Info.plist
        let raw = (Bundle.main.infoDictionary?["API_MODE"] as? String ?? "live").lowercased()
        return APIMode(rawValue: raw) ?? .live
    }
}

// MARK: - AppConfig (single source of truth)

struct AppConfig {
    static let shared = AppConfig()

    let environment: AppEnvironment = .current
    let apiMode: APIMode = .current
    var useLocalBackend: Bool {
        (Bundle.main.infoDictionary?["APP_USE_LOCAL_BACKEND"] as? String) == "1"
    }
    var localBaseURL: String? {
        guard let value = Bundle.main.infoDictionary?["APP_LOCAL_BASE_URL"] as? String else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    var baseURL: String {
        if useLocalBackend {
            if let localBaseURL, let normalized = normalizedBaseURL(localBaseURL) {
                return normalized
            }
            return "http://localhost:3000"
        }
        if let raw = Bundle.main.infoDictionary?["APP_BASE_URL"] as? String,
           let normalized = normalizedBaseURL(raw) {
            return normalized
        }
        return environment.defaultBaseURL
    }
    var isDebug: Bool { environment.isDebugLoggingEnabled || useLocalBackend }
    var isMockAPI: Bool { apiMode == .mock }

    var timeoutInterval: TimeInterval { 30 }
    var clientVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private init() {}

    private func normalizedBaseURL(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let url = URL(string: trimmed),
              let scheme = url.scheme, !scheme.isEmpty,
              let host = url.host, !host.isEmpty else {
            return nil
        }
        return trimmed
    }
}
