//
//  NotificationRepository.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - NotificationRepository

final class NotificationRepository: NotificationRepositoryProtocol, @unchecked Sendable {

    private let remoteDataSource: RemoteNotificationDataSource

    init(remoteDataSource: RemoteNotificationDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchNotifications(page: Int, perPage: Int) async throws -> [AppNotification] {
        try await remoteDataSource.fetchNotifications(page: page, perPage: perPage)
    }

    func markAsRead(id: String) async throws {
        try await remoteDataSource.markAsRead(id: id)
    }

    func markAllAsRead() async throws {
        try await remoteDataSource.markAllAsRead()
    }

    func fetchUnreadCount() async throws -> Int {
        try await remoteDataSource.fetchUnreadCount()
    }
}
