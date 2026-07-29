//
//  PushNotificationService.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import UserNotifications
import UIKit
import Combine

// MARK: - PushNotificationType

/// Categories of push notifications the app handles.
enum PushNotificationType: String, Sendable {
    case message = "message"
    case like = "like"
    case comment = "comment"
    case follow = "follow"
    case mention = "mention"
    case liveVideo = "live_video"
    case callMissed = "call_missed"
    case generic = "generic"
}

// MARK: - PushNotificationPayload

/// Parsed push notification payload.
struct PushNotificationPayload: Sendable {
    let type: PushNotificationType
    let title: String?
    let body: String?
    let imageURL: URL?
    let data: [String: Any]

    // Routing info
    let userId: String?
    let postId: String?
    let conversationId: String?
    let commentId: String?

    init(userInfo: [AnyHashable: Any]) {
        let aps = userInfo["aps"] as? [String: Any] ?? [:]
        let alert = aps["alert"] as? [String: Any]
        let customData = userInfo["data"] as? [String: Any] ?? [:]

        self.title = alert?["title"] as? String
        self.body = alert?["body"] as? String

        let typeRaw = customData["type"] as? String ?? userInfo["type"] as? String ?? "generic"
        self.type = PushNotificationType(rawValue: typeRaw) ?? .generic

        self.imageURL = (customData["image_url"] as? String).flatMap { URL(string: $0) }
        self.data = customData

        // Routing
        self.userId = customData["user_id"] as? String
        self.postId = customData["post_id"] as? String
        self.conversationId = customData["conversation_id"] as? String
        self.commentId = customData["comment_id"] as? String
    }
}

// MARK: - PushNotificationServiceProtocol

protocol PushNotificationServiceProtocol: AnyObject {
    var deviceToken: String? { get }
    var notificationTapped: AnyPublisher<PushNotificationPayload, Never> { get }

    func requestAuthorization() async -> Bool
    func registerForRemoteNotifications()
    func handleDeviceToken(_ token: Data)
    func handleNotificationReceived(userInfo: [AnyHashable: Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    func handleNotificationTapped(response: UNNotificationResponse)
}

// MARK: - PushNotificationService

/// Manages regular (APNs) push notifications.
/// Handles registration, permission, token management, and payload routing.
final class PushNotificationService: NSObject, PushNotificationServiceProtocol, @unchecked Sendable {

    static let shared = PushNotificationService()

    // MARK: - Properties

    private(set) var deviceToken: String?
    private let logger = AppLogger.general

    private let notificationTappedSubject = PassthroughSubject<PushNotificationPayload, Never>()
    private let notificationReceivedSubject = PassthroughSubject<PushNotificationPayload, Never>()

    /// Emits when user taps a notification (for navigation).
    var notificationTapped: AnyPublisher<PushNotificationPayload, Never> {
        notificationTappedSubject.eraseToAnyPublisher()
    }

    /// Emits when a notification is received in foreground.
    var notificationReceived: AnyPublisher<PushNotificationPayload, Never> {
        notificationReceivedSubject.eraseToAnyPublisher()
    }

    private override init() {
        super.init()
    }

    // MARK: - Authorization

    /// Request notification permissions. Returns true if authorized.
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound, .provisional])
            logger.info("Push notification authorization: \(granted ? "granted" : "denied")")

            if granted {
                await setupNotificationCategories()
            }
            return granted
        } catch {
            logger.error("Push notification authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Registration

    /// Call this after authorization to register with APNs.
    @MainActor
    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    // MARK: - Token

    func handleDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = tokenString
        logger.info("APNs device token: \(tokenString.prefix(16))...")

        // TODO: Send token to backend
        // NetworkService.registerDeviceToken(tokenString)
    }

    func handleRegistrationError(_ error: Error) {
        logger.error("APNs registration failed: \(error.localizedDescription)")
    }

    // MARK: - Receive Notification (background/foreground)

    func handleNotificationReceived(
        userInfo: [AnyHashable: Any],
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        let payload = PushNotificationPayload(userInfo: userInfo)
        logger.info("Push received: type=\(payload.type.rawValue)")

        notificationReceivedSubject.send(payload)

        // Process silently (update badge, sync data)
        processSilentNotification(payload)

        completionHandler(.newData)
    }

    // MARK: - Notification Tapped

    func handleNotificationTapped(response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        let payload = PushNotificationPayload(userInfo: userInfo)
        logger.info("Push tapped: type=\(payload.type.rawValue)")

        notificationTappedSubject.send(payload)
    }

    // MARK: - Navigation from Notification

    /// Route to the appropriate screen based on notification payload.
    @MainActor
    func navigateFromPayload(_ payload: PushNotificationPayload) {
        let router = AppRouter.shared

        switch payload.type {
        case .message:
            if let conversationId = payload.conversationId {
                router.switchTab(.feed)
                router.push(.directMessages)
                router.push(.conversation(conversationId: conversationId))
            }

        case .like, .comment, .mention:
            if let postId = payload.postId {
                router.switchTab(.feed)
                router.push(.postDetail(postId: postId))
            }

        case .follow:
            if let userId = payload.userId {
                router.switchTab(.profile)
                router.push(.userProfile(userId: userId))
            }

        case .callMissed:
            if let _ = payload.userId {
                router.switchTab(.feed)
                router.push(.directMessages)
            }

        case .liveVideo, .generic:
            break
        }
    }

    // MARK: - Badge Management

    @MainActor
    func updateBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }

    @MainActor
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    // MARK: - Private

    private func setupNotificationCategories() async {
        let center = UNUserNotificationCenter.current()

        // Message category: reply inline
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type a message..."
        )

        let messageCategory = UNNotificationCategory(
            identifier: "MESSAGE",
            actions: [replyAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        // Like category: view post
        let viewPostAction = UNNotificationAction(
            identifier: "VIEW_POST_ACTION",
            title: "View Post",
            options: .foreground
        )

        let likeCategory = UNNotificationCategory(
            identifier: "LIKE",
            actions: [viewPostAction],
            intentIdentifiers: [],
            options: []
        )

        // Follow category: view profile
        let viewProfileAction = UNNotificationAction(
            identifier: "VIEW_PROFILE_ACTION",
            title: "View Profile",
            options: .foreground
        )

        let followCategory = UNNotificationCategory(
            identifier: "FOLLOW",
            actions: [viewProfileAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([messageCategory, likeCategory, followCategory])
    }

    private func processSilentNotification(_ payload: PushNotificationPayload) {
        // Background processing: sync data, update local state
        switch payload.type {
        case .message:
            // Trigger message sync
            break
        default:
            break
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {

    /// Called when notification received while app is in foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let payload = PushNotificationPayload(userInfo: notification.request.content.userInfo)
        notificationReceivedSubject.send(payload)

        // Show banner in foreground for most types (not for active conversation)
        completionHandler([.banner, .sound, .badge])
    }

    /// Called when user taps a notification.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotificationTapped(response: response)
        completionHandler()
    }
}
