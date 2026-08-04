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
    let type: String        // "LIKE" | "COMMENT" | "FOLLOW" | "FOLLOW_REQUEST" | "MENTION" | "TAGGED_IN_POST" | "STORY_MENTION" | "LIVE_VIDEO" (uppercase)
    let postId: String?
    let commentText: String?
    let isRead: Bool
    let createdAt: String
    let actor: UserDTO
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
