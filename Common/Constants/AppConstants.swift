//
//  AppConstants.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 20/7/26.
//

import Foundation

enum AppConstants {
    
    enum App {
        static let name: String = {
            Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleName"] as? String
            ?? "InstagramClone"
        }()
        static let bundleID           = Bundle.main.bundleIdentifier ?? "com.tomthecat.InstagramClone"
        static let coreDataModelName  = "AppModel"
        static let deepLinkScheme     = "myapp"   // myapp://path
        static let universalLinkHost  = "http://localhost:3000"
    }
    
    enum Storage {
        static let sqlitePath: String = {
            guard let docs = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask).first else {
                return NSTemporaryDirectory() + "app.sqlite"
            }
            return docs.appendingPathComponent("app.sqlite").path
        }()
    }

    enum Keychain {
        static let service = AppConstants.App.bundleID
    }
}

// MARK: - Keychain Keys
// Keys are scoped by AppConstants.Keychain.service (= Bundle.main.bundleIdentifier)
// to avoid collision when multiple apps share the same keychain access group.
// Do NOT use hardcoded prefixes like "com.app.auth.*" — use the bundle-derived service
// so keys remain unique per app even in shared-keychain environments (e.g. App Extensions).
enum KeychainKeys {
    private static let prefix = AppConstants.Keychain.service
    static let accessToken      = "\(prefix).auth.accessToken"
    static let refreshToken     = "\(prefix).auth.refreshToken"
    static let biometricEnabled = "\(prefix).auth.biometricEnabled"
}
