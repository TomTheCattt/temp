//
//  FirebaseNotificationDataSource.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation

// MARK: - FirebaseNotificationDataSource

/// Skeletal actor for Firebase Notifications.
/// Ready for rewriting logic from scratch.
actor FirebaseNotificationDataSource {

    static let shared = FirebaseNotificationDataSource()

    init() {}

    func fetchNotifications(page: Int, perPage: Int) async throws -> [AppNotification] {
        _ = page
        _ = perPage
        // TODO: Implement fetchNotifications logic from scratch
        return []
    }

    func markAsRead(id: String) async throws {
        _ = id
        // TODO: Implement markAsRead logic from scratch
    }

    func markAllAsRead() async throws {
        // TODO: Implement markAllAsRead logic from scratch
    }

    func fetchUnreadCount() async throws -> Int {
        // TODO: Implement fetchUnreadCount logic from scratch
        return 0
    }
}
