//
//  FetchUnreadNotificationCountUseCase.swift
//  Instagram
//
//  Created by Antigravity on 22/10/26.
//

import Foundation

// MARK: - FetchUnreadNotificationCountUseCaseProtocol

protocol FetchUnreadNotificationCountUseCaseProtocol: Sendable {
    func execute() async throws -> Int
}

// MARK: - FetchUnreadNotificationCountUseCase

final class FetchUnreadNotificationCountUseCase: FetchUnreadNotificationCountUseCaseProtocol, Sendable {

    private let notificationRepository: NotificationRepositoryProtocol

    init(notificationRepository: NotificationRepositoryProtocol) {
        self.notificationRepository = notificationRepository
    }

    func execute() async throws -> Int {
        try await notificationRepository.fetchUnreadCount()
    }
}
