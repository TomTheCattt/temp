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
            postThumbnailURL: dto.postThumbnailUrl.flatMap { URL(string: $0) },
            commentText: dto.commentText,
            isRead: dto.isRead,
            createdAt: DateMapper.toDate(dto.createdAt)
        )
    }

    static func toEntityList(_ dtos: [NotificationDTO]) -> [AppNotification] {
        dtos.map { toEntity($0) }
    }

    // MARK: - Type

    private static func toNotificationType(_ raw: String) -> NotificationType {
        switch raw {
        case "like":            return .like
        case "comment":         return .comment
        case "follow":          return .follow
        case "followRequest":   return .followRequest
        case "mention":         return .mention
        case "taggedInPost":    return .taggedInPost
        case "storyMention":    return .storyMention
        case "liveVideo":       return .liveVideo
        default:                return .like
        }
    }
}
