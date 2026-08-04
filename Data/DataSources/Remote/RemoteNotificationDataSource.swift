//
//  RemoteNotificationDataSource.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - RemoteNotificationDataSource

final class RemoteNotificationDataSource: @unchecked Sendable {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    // MARK: - Fetch

    func fetchNotifications(page: Int, perPage: Int) async throws -> [AppNotification] {
        let response: PaginatedNotificationsDTO = try await networkService.requestEnvelope(
            NotificationEndpoint.list(page: page, perPage: perPage)
        )
        return NotificationMapper.toEntityList(response.items)
    }

    // MARK: - Unread Count

    func fetchUnreadCount() async throws -> Int {
        let response: UnreadCountDTO = try await networkService.requestEnvelope(
            NotificationEndpoint.unreadCount
        )
        return response.count
    }

    // MARK: - Mark Read

    func markAsRead(id: String) async throws {
        try await networkService.requestVoid(NotificationEndpoint.markRead(id: id))
    }

    func markAllAsRead() async throws {
        try await networkService.requestVoid(NotificationEndpoint.markAllRead)
    }
}
