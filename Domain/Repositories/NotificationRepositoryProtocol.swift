//
//  NotificationRepositoryProtocol.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - NotificationRepositoryProtocol

protocol NotificationRepositoryProtocol: Sendable {

    /// Fetch notifications list.
    func fetchNotifications(page: Int, perPage: Int) async throws -> [AppNotification]

    /// Mark a notification as read.
    func markAsRead(id: String) async throws

    /// Mark all notifications as read.
    func markAllAsRead() async throws

    /// Get unread count.
    func fetchUnreadCount() async throws -> Int
}
