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
            try await markNotificationsAsReadUseCase.execute()
            AppState.shared.setUnreadNotificationCount(0)
            if !notifications.isEmpty {
                notifications = notifications.map { item in
                    AppNotification(
                        id: item.id,
                        type: item.type,
                        actor: item.actor,
                        postId: item.postId,
                        postThumbnailURL: item.postThumbnailURL,
                        commentText: item.commentText,
                        isRead: true,
                        createdAt: item.createdAt
                    )
                }
            }
        } catch {
            // Silent fail
        }
    }
}
