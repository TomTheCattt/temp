//
//  NotificationMapper.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - NotificationMapper

enum NotificationMapper {

    static func toEntity(_ dto: NotificationDTO) -> AppNotification {
        AppNotification(
            id: dto.id,
            type: toNotificationType(dto.type),
            actor: UserMapper.toEntity(dto.actor),
            postId: dto.postId,
            postThumbnailURL: nil, // BE doesn't include post thumbnail in notification
            commentText: dto.commentText,
            isRead: dto.isRead,
            createdAt: DateMapper.toDate(dto.createdAt)
        )
    }

    static func toEntityList(_ dtos: [NotificationDTO]) -> [AppNotification] {
        dtos.map { toEntity($0) }
    }

    // MARK: - NotificationType

    private static func toNotificationType(_ raw: String) -> NotificationType {
        switch raw.uppercased() {
        case "LIKE":            return .like
        case "COMMENT":         return .comment
        case "FOLLOW":          return .follow
        case "FOLLOW_REQUEST":  return .followRequest
        case "MENTION":         return .mention
        case "TAGGED_IN_POST":  return .taggedInPost
        case "STORY_MENTION":   return .storyMention
        case "LIVE_VIDEO":      return .liveVideo
        default:                return .like
        }
    }
}
