//
//  NotificationRouter.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Combine

// MARK: - NotificationRouter

/// Coordinates navigation from push notification taps.
/// Subscribes to PushNotificationService.notificationTapped and routes accordingly.
@MainActor
final class NotificationRouter {

    static let shared = NotificationRouter()

    private var cancellables = Set<AnyCancellable>()
    private let pushService: PushNotificationService

    private init(pushService: PushNotificationService? = nil) {
        self.pushService = pushService ?? PushNotificationService.shared
        subscribe()
    }

    private func subscribe() {
        pushService.notificationTapped
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payload in
                guard let self else { return }
                Task { @MainActor in
                    self.pushService.navigateFromPayload(payload)
                }
            }
            .store(in: &cancellables)
    }
}
