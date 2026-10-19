//
//  FirebaseNotificationRepository.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation

// MARK: - FirebaseNotificationRepository

final class FirebaseNotificationRepository: NotificationRepositoryProtocol, @unchecked Sendable {

    private let dataSource: FirebaseNotificationDataSource

    init(dataSource: FirebaseNotificationDataSource = FirebaseNotificationDataSource()) {
        self.dataSource = dataSource
    }

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
