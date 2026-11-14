//
//  NotificationDTO.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - NotificationDTO

/// API response model for Notification. Matches BE response format.
nonisolated struct NotificationDTO: Decodable, Sendable {
    let id: String
    let recipientId: String
    let actorId: String
    let type: String
    let referenceType: String?
    let referenceId: String?
    let previewText: String?
    let thumbnailUrl: String?
    let deepLink: String?
    // Legacy fallback fields
    let postId: String?
    let postThumbnailUrl: String?
    let commentText: String?
    let isRead: Bool
    let createdAt: String
    let actor: NotificationActorDTO

    var resolvedReferenceId: String? {
        referenceId ?? postId
    }

    var resolvedThumbnailUrl: String? {
        thumbnailUrl ?? postThumbnailUrl
    }

    var resolvedPreviewText: String? {
        previewText ?? commentText
    }
}

// MARK: - PaginatedNotificationsDTO

nonisolated struct PaginatedNotificationsDTO: Decodable, Sendable {
    let items: [NotificationDTO]
    let page: Int
    let perPage: Int
    let total: Int
    let hasMore: Bool
}

// MARK: - UnreadCountDTO

nonisolated struct UnreadCountDTO: Decodable, Sendable {
    let count: Int
}

// MARK: - NotificationActorDTO

/// Lightweight user object returned in notification contexts.
/// BE returns: id, username, fullName, avatarUrl, isVerified, isFollowing
nonisolated struct NotificationActorDTO: Decodable, Sendable {
    let id: String
    let username: String?
    let fullName: String?
    let avatarUrl: String?
    let isVerified: Bool?
    let isFollowing: Bool?
}
