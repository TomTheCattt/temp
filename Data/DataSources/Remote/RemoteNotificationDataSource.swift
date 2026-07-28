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

    func fetchNotifications(page: Int, perPage: Int) async throws -> [AppNotification] {
        let response: PaginatedResponseDTO<NotificationDTO> = try await networkService.request(
            NotificationEndpoint.list(page: page, perPage: perPage)
        )
        return NotificationMapper.toEntityList(response.items)
    }

    func markAsRead(id: String) async throws {
        try await networkService.requestVoid(NotificationEndpoint.markRead(id: id))
    }

    func markAllAsRead() async throws {
        try await networkService.requestVoid(NotificationEndpoint.markAllRead)
    }
}
