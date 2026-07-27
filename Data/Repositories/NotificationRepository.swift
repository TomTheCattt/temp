//
//  NotificationRepository.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - NotificationRepository

final class NotificationRepository: NotificationRepositoryProtocol, @unchecked Sendable {

    private let mockDataSource: MockNotificationDataSource

    init(mockDataSource: MockNotificationDataSource = MockNotificationDataSource()) {
        self.mockDataSource = mockDataSource
    }

    func fetchNotifications(page: Int, perPage: Int) async throws -> [AppNotification] {
        try await mockDataSource.fetchNotifications(page: page, perPage: perPage)
    }

    func markAsRead(id: String) async throws {
        try await mockDataSource.markAsRead(id: id)
    }

    func markAllAsRead() async throws {
        try await mockDataSource.markAllAsRead()
    }

    func fetchUnreadCount() async throws -> Int {
        try await mockDataSource.fetchUnreadCount()
    }
}
