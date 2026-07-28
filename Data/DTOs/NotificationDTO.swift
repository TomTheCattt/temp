//
//  NotificationDTO.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - NotificationDTO

/// API response model for Notification.
nonisolated struct NotificationDTO: Decodable, Sendable {
    let id: String
    let type: String // "like" | "comment" | "follow" | "followRequest" | "mention" | "taggedInPost" | "storyMention" | "liveVideo"
    let actor: UserDTO
    let postId: String?
    let postThumbnailUrl: String?
    let commentText: String?
    let isRead: Bool
    let createdAt: String
}
