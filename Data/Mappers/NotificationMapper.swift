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
        let thumbUrl = dto.resolvedThumbnailUrl.flatMap { URL(string: $0) }
        let preview = dto.resolvedPreviewText
        let refId = dto.resolvedReferenceId

        return AppNotification(
            id: dto.id,
            type: toNotificationType(dto.type),
            actor: toActor(dto.actor),
            referenceType: dto.referenceType,
            referenceId: refId,
            previewText: preview,
            thumbnailURL: thumbUrl,
            deepLink: dto.deepLink,
            postId: refId,
            postThumbnailURL: thumbUrl,
            commentText: preview,
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
        case "LIKE":                 return .like
        case "COMMENT":              return .comment
        case "FOLLOW":               return .follow
        case "FOLLOW_REQUEST":       return .followRequest
        case "FOLLOW_ACCEPT":        return .followAccept
        case "MENTION":              return .mention
        case "TAGGED_IN_POST":       return .taggedInPost
        case "TAGGED_IN_COMMENT":    return .taggedInComment
        case "TAGGED_IN_STORY":      return .taggedInStory
        case "STORY_MENTION":        return .storyMention
        case "STORY_REPLY":          return .storyReply
        case "REEL_LIKE":            return .reelLike
        case "REEL_COMMENT":         return .reelComment
        case "LIVE_VIDEO":           return .liveVideo
        case "LIVE_JOIN":            return .liveJoin
        case "DM_MESSAGE", "MESSAGE": return .dmMessage
        case "DM_REACTION":          return .dmReaction
        case "CALL":                 return .call
        case "LIVE":                 return .live
        case "NEW_REEL":             return .newReel
        case "NEW_STORY":            return .newStory
        default:                     return .like
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
