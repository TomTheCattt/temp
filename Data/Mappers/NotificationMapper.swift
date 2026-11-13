//
//  NotificationMapper.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - NotificationMapper

nonisolated enum NotificationMapper {

    static func toEntity(_ dto: NotificationDTO) -> AppNotification {
        AppNotification(
            id: dto.id,
            type: toNotificationType(dto.type),
            actor: toActor(dto.actor),
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
        case "MESSAGE":         return .message
        case "CALL":            return .call
        case "LIVE":            return .live
        case "NEW_REEL":        return .newReel
        case "NEW_STORY":       return .newStory
        default:                return .like
        }
    }

    // MARK: - Actor Mapping

    private static func toActor(_ dto: NotificationActorDTO) -> User {
        User(
            id: dto.id,
            username: dto.username ?? "",
            fullName: dto.fullName ?? "",
            email: nil,
            phone: nil,
            avatarURL: dto.avatarUrl.flatMap { URL(string: $0) },
            bio: nil,
            website: nil,
            isVerified: dto.isVerified ?? false,
            isPrivate: false,
            followersCount: 0,
            followingCount: 0,
            postsCount: 0,
            createdAt: .now,
            isFollowing: dto.isFollowing ?? false,
            isFollowedBy: false,
            isBlocked: false
        )
    }
}
