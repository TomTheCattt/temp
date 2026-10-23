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
        // TODO: Implement loadNotifications logic from scratch
    }

    func markAllAsRead() async {
        // TODO: Implement markAllAsRead logic from scratch
    }
}
