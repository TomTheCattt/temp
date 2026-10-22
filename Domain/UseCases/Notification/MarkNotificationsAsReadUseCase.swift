//
//  MarkNotificationsAsReadUseCase.swift
//  Instagram
//
//  Created by Antigravity on 22/10/26.
//

import Foundation

// MARK: - MarkNotificationsAsReadUseCaseProtocol

protocol MarkNotificationsAsReadUseCaseProtocol: Sendable {
    func execute() async throws
}

// MARK: - MarkNotificationsAsReadUseCase

final class MarkNotificationsAsReadUseCase: MarkNotificationsAsReadUseCaseProtocol, Sendable {

    private let notificationRepository: NotificationRepositoryProtocol

    init(notificationRepository: NotificationRepositoryProtocol) {
        self.notificationRepository = notificationRepository
    }

    func execute() async throws {
        try await notificationRepository.markAllAsRead()
    }
}
