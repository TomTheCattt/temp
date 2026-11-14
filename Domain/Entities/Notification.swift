//
//  Notification.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - AppNotification

/// Named `AppNotification` to avoid collision with Foundation.Notification.
nonisolated struct AppNotification: Identifiable, Hashable, Sendable {
    let id: String
    let type: NotificationType
    let actor: User           // who triggered the notification
    let referenceType: String?
    let referenceId: String?
    let previewText: String?
    let thumbnailURL: URL?
    let deepLink: String?
    let isRead: Bool
    let createdAt: Date

    // Backward compatibility aliases
    var postId: String? { referenceId }
    var postThumbnailURL: URL? { thumbnailURL }
    var commentText: String? { previewText }

    init(
        id: String,
        type: NotificationType,
        actor: User,
        referenceType: String? = nil,
        referenceId: String? = nil,
        previewText: String? = nil,
        thumbnailURL: URL? = nil,
        deepLink: String? = nil,
        postId: String? = nil,
        postThumbnailURL: URL? = nil,
        commentText: String? = nil,
        isRead: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.type = type
        self.actor = actor
        self.referenceType = referenceType ?? (postId != nil ? "post" : nil)
        self.referenceId = referenceId ?? postId
        self.previewText = previewText ?? commentText
        self.thumbnailURL = thumbnailURL ?? postThumbnailURL
        self.deepLink = deepLink
        self.isRead = isRead
        self.createdAt = createdAt
    }
}
