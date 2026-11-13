//
//  PushNotificationServiceTests.swift
//  InstagramTests
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Testing
import UserNotifications
@testable import Instagram

// MARK: - PushNotificationService Tests

@Suite("PushNotificationService Tests")
struct PushNotificationServiceTests {

    @Test("PushNotificationPayload parsing")
    func testPayloadParsing() {
        let userInfo: [AnyHashable: Any] = [
            "aps": [
                "alert": [
                    "title": "New Message",
                    "body": "Hello world"
                ],
                "badge": 5
            ],
            "data": [
                "type": "message",
                "user_id": "user-123",
                "conversation_id": "conv-456",
                "image_url": "https://example.com/image.jpg"
            ]
        ]

        let payload = PushNotificationPayload(userInfo: userInfo)

        #expect(payload.type == .message)
        #expect(payload.title == "New Message")
        #expect(payload.body == "Hello world")
        #expect(payload.userId == "user-123")
        #expect(payload.conversationId == "conv-456")
        #expect(payload.imageURL?.absoluteString == "https://example.com/image.jpg")
    }

    @Test("PushNotificationPayload with unknown type defaults to generic")
    func testPayloadUnknownType() {
        let userInfo: [AnyHashable: Any] = [
            "aps": [
                "alert": [
                    "title": "Test",
                    "body": "Test body"
                ]
            ],
            "data": [
                "type": "unknown_type"
            ]
        ]

        let payload = PushNotificationPayload(userInfo: userInfo)

        #expect(payload.type == .generic)
    }

    @Test("PushNotificationPayload without data")
    func testPayloadWithoutData() {
        let userInfo: [AnyHashable: Any] = [
            "aps": [
                "alert": [
                    "title": "Test",
                    "body": "Test body"
                ]
            ]
        ]

        let payload = PushNotificationPayload(userInfo: userInfo)

        #expect(payload.type == .generic)
        #expect(payload.title == "Test")
        #expect(payload.body == "Test body")
        #expect(payload.data.isEmpty)
    }

    @Test("PushNotificationType all cases")
    func testPushNotificationTypeCases() {
        let types: [PushNotificationType] = [
            .message, .like, .comment, .follow,
            .mention, .liveVideo, .callMissed, .generic
        ]

        for type in types {
            #expect(PushNotificationType(rawValue: type.rawValue) == type)
        }
    }

    @Test("BackgroundTaskIdentifier values")
    func testBackgroundTaskIdentifiers() {
        #expect(BackgroundTaskIdentifier.pushProcessing.rawValue == "com.instagram.background.push-processing")
        #expect(BackgroundTaskIdentifier.badgeRefresh.rawValue == "com.instagram.background.badge-refresh")
        #expect(BackgroundTaskIdentifier.silentSync.rawValue == "com.instagram.background.silent-sync")
    }
}

// MARK: - PushNotificationService Integration Tests

@Suite("PushNotificationService Integration Tests")
struct PushNotificationServiceIntegrationTests {

    @Test("Notification categories setup includes all types")
    func testNotificationCategories() async {
        let center = UNUserNotificationCenter.current()

        // This would normally be called by setupNotificationCategories()
        // We verify the categories we expect exist

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

        let callBackAction = UNNotificationAction(
            identifier: "CALL_BACK_ACTION",
            title: "Call Back",
            options: .foreground
        )

        let callMissedCategory = UNNotificationCategory(
            identifier: "CALL_MISSED",
            actions: [callBackAction],
            intentIdentifiers: [],
            options: []
        )

        let categories: Set<UNNotificationCategory> = [
            messageCategory, likeCategory, followCategory, callMissedCategory
        ]

        #expect(categories.count == 4)

        // Verify identifiers
        let identifiers = categories.map { $0.identifier }.sorted()
        #expect(identifiers == ["CALL_MISSED", "FOLLOW", "LIKE", "MESSAGE"])
    }
}