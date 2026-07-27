//
//  NotificationsViewModel.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - NotificationsViewModel

@MainActor
@Observable
final class NotificationsViewModel {

    // MARK: - State

    private(set) var notifications: [AppNotification] = []
    private(set) var isLoading = false

    // MARK: - Dependencies

    private let fetchNotificationsUseCase: FetchNotificationsUseCaseProtocol
    private let notificationRepository: NotificationRepositoryProtocol

    // MARK: - Init

    init(
        fetchNotificationsUseCase: FetchNotificationsUseCaseProtocol,
        notificationRepository: NotificationRepositoryProtocol
    ) {
        self.fetchNotificationsUseCase = fetchNotificationsUseCase
        self.notificationRepository = notificationRepository
    }

    // MARK: - Actions

    func loadNotifications() async {
        guard !isLoading else { return }
        isLoading = true

        do {
            notifications = try await fetchNotificationsUseCase.execute(
                PaginationInput(page: 1, perPage: 50)
            )
        } catch {
            // Silent fail
        }

        isLoading = false
    }

    func markAllAsRead() async {
        do {
            try await notificationRepository.markAllAsRead()
        } catch {
            // Silent fail
        }
    }
}
