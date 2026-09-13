//
//  UserSettings.swift
//  Instagram
//
//  Created by Kiro on 13/9/26.
//

import Foundation

// MARK: - UserSettings

/// Per-account preferences persisted server-side (notifications + data usage).
/// These follow the user across devices, unlike purely local prefs (e.g. theme).
struct UserSettings: Hashable, Sendable {

    // Notifications
    var pushEnabled: Bool
    var likeNotifications: Bool
    var commentNotifications: Bool
    var followNotifications: Bool
    var directMessageNotifications: Bool

    // Privacy
    var activityStatusVisible: Bool

    // Data & storage
    var highQualityUploads: Bool
    var cellularDataEnabled: Bool
}

// MARK: - Defaults

extension UserSettings {
    /// Sensible defaults, used before the server value loads or on failure.
    static let `default` = UserSettings(
        pushEnabled: true,
        likeNotifications: true,
        commentNotifications: true,
        followNotifications: true,
        directMessageNotifications: true,
        activityStatusVisible: true,
        highQualityUploads: true,
        cellularDataEnabled: true
    )
}
