//
//  MockNotificationDataSource.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - MockNotificationDataSource

final class MockNotificationDataSource: Sendable {

    func fetchNotifications(page: Int, perPage: Int) async throws -> [AppNotification] {
        try await simulateDelay()
        return MockData.notifications
    }

    func markAsRead(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
    }

    func markAllAsRead() async throws {
        try await simulateDelay(seconds: 0.3)
    }

    func fetchUnreadCount() async throws -> Int {
        try await simulateDelay(seconds: 0.2)
        return MockData.notifications.filter { !$0.isRead }.count
    }

    // MARK: - Private

    private func simulateDelay(seconds: Double = 0.5) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
