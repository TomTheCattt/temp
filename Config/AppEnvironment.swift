//
//  AppEnvironment.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 20/7/26.
//

import Foundation

// MARK: - Config Keys

enum ConfigKey {
    static let environment = "APP_ENVIRONMENT"
    static let backendType = "BACKEND_TYPE"
    static let baseURL = "APP_BASE_URL"
    static let appStoreURL = "APP_STORE_URL"
    static let debugLogging = "ENABLE_DEBUG_LOGGING"
    static let useLocalBackend = "APP_USE_LOCAL_BACKEND"
    static let localBaseURL = "APP_LOCAL_BASE_URL"
    static let callBackendMode = "CALL_BACKEND_MODE"
    static let bundleVersion = "CFBundleVersion"
    static let bundleShortVersion = "CFBundleShortVersionString"
}

// MARK: - BackendType

enum BackendType: String {
    case live

    /// Resolves Backend Type from:
    /// 1. Process environment variable (set via Xcode scheme) — highest priority
    /// 2. Info.plist key (set via xcconfig)
    /// 3. Default fallback to .live (Neon backend)
    static var current: BackendType {
        // Priority 1: Scheme environment variable
        if let envValue = ProcessInfo.processInfo.environment[ConfigKey.backendType]?.lowercased(),
           let type = BackendType(rawValue: envValue) {
            return type
        }
        // Priority 2: Info.plist
        if let raw = (Bundle.main.infoDictionary?[ConfigKey.backendType] as? String)?.lowercased(),
           let type = BackendType(rawValue: raw) {
            return type
        }
        // Priority 3: Default fallback to live (Neon backend)
        return .live
    }
}

// MARK: - APIMode (Typealias for backward compatibility)

typealias APIMode = BackendType

// MARK: - AppEnvironment

enum AppEnvironment: String {
    case development  = "dev"
    case staging      = "staging"
    case production   = "prod"

    // Reads from process environment (scheme) first, then Info.plist key APP_ENVIRONMENT.
    static var current: AppEnvironment {
        // Priority 1: Scheme environment variable
        if let envValue = ProcessInfo.processInfo.environment[ConfigKey.environment],
           let env = AppEnvironment(rawValue: envValue) {
            return env
        }
        // Priority 2: Info.plist
        let raw = Bundle.main.infoDictionary?[ConfigKey.environment] as? String ?? "prod"
        return AppEnvironment(rawValue: raw) ?? .production
    }

    var isDebugLoggingEnabled: Bool {
        if let raw = Bundle.main.infoDictionary?[ConfigKey.debugLogging] as? String {
            return raw.uppercased() == "YES" || raw == "1"
        }
        return self != .production
    }

    var displayName: String {
        switch self {
        case .development:  return "DEV"
        case .staging:      return "STAGING"
        case .production:   return ""
        }
    }
}

// MARK: - AppConfig (single source of truth)

struct AppConfig {
    static let shared = AppConfig()

    let environment: AppEnvironment = .current
    let backendType: BackendType = .current
    var apiMode: BackendType { backendType }

    var useLocalBackend: Bool {
        // Priority 1: Scheme environment variable
        if let envValue = ProcessInfo.processInfo.environment[ConfigKey.useLocalBackend] {
            return envValue == "1"
        }
        // Priority 2: Info.plist
        return (Bundle.main.infoDictionary?[ConfigKey.useLocalBackend] as? String) == "1"
    }

    var localBaseURL: String? {
        // Priority 1: Scheme environment variable
        if let envValue = ProcessInfo.processInfo.environment[ConfigKey.localBaseURL],
           !envValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return envValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Priority 2: Info.plist
        guard let value = Bundle.main.infoDictionary?[ConfigKey.localBaseURL] as? String else {
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
            // Auto-detect: Simulator uses localhost, physical device uses LAN IP
            #if targetEnvironment(simulator)
            return "http://localhost:8787"
            #else
            return "http://192.168.1.107:8787"
            #endif
        }
        if let raw = Bundle.main.infoDictionary?[ConfigKey.baseURL] as? String,
           let normalized = normalizedBaseURL(raw) {
            return normalized
        }
        return "https://api.example.com"
    }

    /// WebSocket base URL (different port from API)
    var wsBaseURL: String {
        if useLocalBackend {
            if let localBaseURL, let normalized = normalizedBaseURL(localBaseURL) {
                // Replace port with WebSocket port
                var components = URLComponents(string: normalized)
                components?.port = 8788
                components?.scheme = "ws"
                return components?.string ?? "ws://localhost:8788"
            }
            // Auto-detect: Simulator uses localhost, physical device uses LAN IP
            #if targetEnvironment(simulator)
            return "ws://localhost:8788"
            #else
            return "ws://192.168.1.107:8788"
            #endif
        }
        if let raw = Bundle.main.infoDictionary?[ConfigKey.baseURL] as? String,
           let normalized = normalizedBaseURL(raw) {
            var components = URLComponents(string: normalized)
            components?.port = 443 // wss default
            components?.scheme = "wss"
            return components?.string ?? "wss://api.example.com"
        }
        return "wss://api.example.com"
    }

    var isDebug: Bool { environment.isDebugLoggingEnabled || useLocalBackend }
    var isFirebaseAPI: Bool { false } // Firebase backend removed
    var isLiveAPI: Bool { true } // Always using Neon live backend

    // MARK: - CallBackendMode

    enum CallBackendMode: String {
        case webSocket
    }

    var callBackendMode: CallBackendMode {
        // Priority 1: Scheme environment variable
        if let envValue = ProcessInfo.processInfo.environment[ConfigKey.callBackendMode]?.lowercased(),
           let mode = CallBackendMode(rawValue: envValue) {
            return mode
        }
        // Priority 2: Info.plist
        if let raw = (Bundle.main.infoDictionary?[ConfigKey.callBackendMode] as? String)?.lowercased(),
           let mode = CallBackendMode(rawValue: raw) {
            return mode
        }
        return .webSocket
    }

    var timeoutInterval: TimeInterval { 30 }

    /// App Store product URL used by the force-update screen ("Update now").
    var appStoreURL: URL? {
        if let raw = Bundle.main.infoDictionary?[ConfigKey.appStoreURL] as? String,
           let normalized = normalizedBaseURL(raw),
           let url = URL(string: normalized) {
            return url
        }
        return nil
    }

    var clientVersion: String {
        Bundle.main.infoDictionary?[ConfigKey.bundleShortVersion] as? String ?? "1.0"
    }
    var buildNumber: String {
        Bundle.main.infoDictionary?[ConfigKey.bundleVersion] as? String ?? "1"
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

// MARK: - Retry Policy

struct RetryPolicy: Sendable {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let jitterFactor: Double
    let retryableStatusCodes: Set<Int>
    let retryableErrors: Set<URLError.Code>

    static let `default` = RetryPolicy(
        maxAttempts: 3,
        baseDelay: 0.5,
        maxDelay: 8.0,
        jitterFactor: 0.3,
        retryableStatusCodes: [408, 429, 500, 502, 503, 504],
        retryableErrors: [
            .timedOut,
            .cannotConnectToHost,
            .networkConnectionLost,
            .dnsLookupFailed,
            .notConnectedToInternet
        ]
    )

    static let aggressive = RetryPolicy(
        maxAttempts: 5,
        baseDelay: 0.25,
        maxDelay: 4.0,
        jitterFactor: 0.5,
        retryableStatusCodes: [408, 429, 500, 502, 503, 504],
        retryableErrors: [
            .timedOut,
            .cannotConnectToHost,
            .networkConnectionLost,
            .dnsLookupFailed,
            .notConnectedToInternet
        ]
    )

    static let none = RetryPolicy(
        maxAttempts: 1,
        baseDelay: 0,
        maxDelay: 0,
        jitterFactor: 0,
        retryableStatusCodes: [],
        retryableErrors: []
    )

    func delay(for attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return 0 }
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt - 1))
        let cappedDelay = min(exponentialDelay, maxDelay)
        let jitter = cappedDelay * jitterFactor * Double.random(in: -1...1)
        return max(0, cappedDelay + jitter)
    }

    func shouldRetry(attempt: Int, error: Error?) -> Bool {
        guard attempt < maxAttempts else { return false }
        // Check for retryable HTTP status codes - these will be checked in NetworkService where AFError is available
        if let urlError = error as? URLError,
           retryableErrors.contains(urlError.code) {
            return true
        }
        // For other errors, we'll check in NetworkService
        return false
    }
}

// MARK: - Rate Limit Policy

struct RateLimitPolicy: Sendable {
    let maxRequestsPerWindow: Int
    let windowDuration: TimeInterval

    static let `default` = RateLimitPolicy(
        maxRequestsPerWindow: 60,
        windowDuration: 60 // 60 requests per minute
    )

    static let strict = RateLimitPolicy(
        maxRequestsPerWindow: 20,
        windowDuration: 60
    )

    static let none = RateLimitPolicy(
        maxRequestsPerWindow: Int.max,
        windowDuration: 1
    )
}

// MARK: - Circuit Breaker Policy

struct CircuitBreakerPolicy: Sendable {
    let failureThreshold: Int
    let successThreshold: Int
    let timeout: TimeInterval

    static let `default` = CircuitBreakerPolicy(
        failureThreshold: 5,
        successThreshold: 2,
        timeout: 30
    )

    static let disabled = CircuitBreakerPolicy(
        failureThreshold: Int.max,
        successThreshold: 1,
        timeout: 0
    )
}

// MARK: - Cache Policy

enum CachePolicy: Sendable {
    case none
    case returnCacheDataElseLoad
    case returnCacheDataDontLoad
    case reloadIgnoringLocalCacheData
    case reloadIgnoringLocalAndRemoteCacheData
}

// MARK: - Request Priority

enum RequestPriority: Int, Sendable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3

    static func < (lhs: RequestPriority, rhs: RequestPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - AppConfig Extensions (Network Policies)

extension AppConfig {
    var retryPolicy: RetryPolicy { .default }
    var rateLimitPolicy: RateLimitPolicy { .default }
    var circuitBreakerPolicy: CircuitBreakerPolicy { .default }
    var defaultCachePolicy: CachePolicy { .none }
    var defaultRequestPriority: RequestPriority { .normal }
}
