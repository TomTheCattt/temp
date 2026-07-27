//
//  Notification.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - AppNotification

/// Named `AppNotification` to avoid collision with Foundation.Notification.
struct AppNotification: Identifiable, Hashable, Sendable {
    let id: String
    let type: NotificationType
    let actor: User           // who triggered the notification
    let postId: String?       // related post (if any)
    let postThumbnailURL: URL?
    let commentText: String?  // for comment notifications
    let isRead: Bool
    let createdAt: Date
}

// MARK: - NotificationType

enum NotificationType: String, Sendable, Hashable {
    case like
    case comment
    case follow
    case followRequest
    case mention
    case taggedInPost
    case storyMention
    case liveVideo
}
