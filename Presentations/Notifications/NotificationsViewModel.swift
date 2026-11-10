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

    var notifications: [AppNotification] = []
    var isLoading = false

    // MARK: - Dependencies

    private let fetchNotificationsUseCase: FetchNotificationsUseCaseProtocol
    private let markNotificationsAsReadUseCase: MarkNotificationsAsReadUseCaseProtocol

    // MARK: - Init

    init(
        fetchNotificationsUseCase: FetchNotificationsUseCaseProtocol,
        markNotificationsAsReadUseCase: MarkNotificationsAsReadUseCaseProtocol
    ) {
        self.fetchNotificationsUseCase = fetchNotificationsUseCase
        self.markNotificationsAsReadUseCase = markNotificationsAsReadUseCase
    }

    // MARK: - Actions

    func loadNotifications() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let notifications = try await fetchNotificationsUseCase.execute(PaginationInput(page: 1, perPage: 20))
            self.notifications = notifications
        } catch {
            AppLogger.general.error("Failed to load notifications: \(error.localizedDescription)")
        }
    }

    func markAllAsRead() async {
        do {
            try await markNotificationsAsReadUseCase.execute()
            // Update local state by creating new notification instances with isRead = true
            self.notifications = notifications.map { notification in
                AppNotification(
                    id: notification.id,
                    type: notification.type,
                    actor: notification.actor,
                    postId: notification.postId,
                    postThumbnailURL: notification.postThumbnailURL,
                    commentText: notification.commentText,
                    isRead: true,
                    createdAt: notification.createdAt
                )
            }
            AppState.shared.setUnreadNotificationCount(0)
        } catch {
            AppLogger.general.error("Failed to mark all notifications as read: \(error.localizedDescription)")
        }
    }
}
