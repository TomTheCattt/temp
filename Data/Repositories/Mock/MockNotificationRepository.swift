//
//  MockNotificationRepository.swift
//  Instagram
//
//  Created by Kiro on 5/8/26.
//

import Foundation

// MARK: - MockNotificationRepository

/// Mock implementation of NotificationRepositoryProtocol for UI testing with local data.
final class MockNotificationRepository: NotificationRepositoryProtocol, @unchecked Sendable {

    private let dataSource = MockNotificationDataSource()

    func fetchNotifications(page: Int, perPage: Int) async throws -> [AppNotification] {
        try await dataSource.fetchNotifications(page: page, perPage: perPage)
    }

    func markAsRead(id: String) async throws {
        try await dataSource.markAsRead(id: id)
    }

    func markAllAsRead() async throws {
        try await dataSource.markAllAsRead()
    }

    func fetchUnreadCount() async throws -> Int {
        try await dataSource.fetchUnreadCount()
    }
}
