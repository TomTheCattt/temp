//
//  NotificationRepository.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - NotificationRepository

final class NotificationRepository: NotificationRepositoryProtocol, @unchecked Sendable {
    func fetchUnreadCount() async throws -> Int {
        return 0
    }
    

    private let remoteDataSource: RemoteNotificationDataSource
    private let mockDataSource: MockNotificationDataSource

    init(
        remoteDataSource: RemoteNotificationDataSource,
        mockDataSource: MockNotificationDataSource = MockNotificationDataSource()
    ) {
        self.remoteDataSource = remoteDataSource
        self.mockDataSource = mockDataSource
    }

    func fetchNotifications(page: Int, perPage: Int) async throws -> [AppNotification] {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchNotifications(page: page, perPage: perPage)
        }
        return try await remoteDataSource.fetchNotifications(page: page, perPage: perPage)
    }

    func markAsRead(id: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.markAsRead(id: id)
        }
        try await remoteDataSource.markAsRead(id: id)
    }

    func markAllAsRead() async throws {
        guard !AppConfig.shared.isMockAPI else {
            try await Task.sleep(nanoseconds: 300_000_000)
            return
        }
        try await remoteDataSource.markAllAsRead()
    }
}
