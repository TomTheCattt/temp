//
//  FetchNotificationsUseCase.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - FetchNotificationsUseCase

protocol FetchNotificationsUseCaseProtocol: Sendable {
    func execute(_ input: PaginationInput) async throws -> [AppNotification]
}

final class FetchNotificationsUseCase: FetchNotificationsUseCaseProtocol, Sendable {

    private let notificationRepository: NotificationRepositoryProtocol

    init(notificationRepository: NotificationRepositoryProtocol) {
        self.notificationRepository = notificationRepository
    }

    func execute(_ input: PaginationInput) async throws -> [AppNotification] {
        try await notificationRepository.fetchNotifications(
            page: input.page,
            perPage: input.perPage
        )
    }
}
