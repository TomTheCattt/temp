//
//  StoryMapper.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - StoryMapper

nonisolated enum StoryMapper {

    static func toEntity(_ dto: StoryDTO) -> Story {
        let resolvedAuthorId = dto.authorId ?? dto.author?.id ?? ""

        // Determine author: from nested object or create minimal from authorId
        let author: User
        if let authorDTO = dto.author {
            author = toUserStory(authorDTO, fallbackId: resolvedAuthorId)
        } else {
            author = User(
                id: resolvedAuthorId,
                username: "",
                fullName: "",
                email: nil,
                phone: nil,
                avatarURL: nil,
                bio: nil,
                website: nil,
                isVerified: false,
                isPrivate: false,
                followersCount: 0,
                followingCount: 0,
                postsCount: 0,
                createdAt: .now,
                isFollowing: false,
                isFollowedBy: false,
                isBlocked: false
            )
        }

        // isViewed: supports new backend viewed: Bool or fallback to non-empty views array
        let isViewed = dto.viewed ?? (!(dto.views ?? []).isEmpty)

        let createdAt = dto.createdAt.map { DateMapper.toDate($0) } ?? .now
        let expiresAt = dto.expiresAt.map { DateMapper.toDate($0) } ?? Date(timeIntervalSinceNow: 86400)

        return Story(
            id: dto.id,
            authorId: resolvedAuthorId,
            author: author,
            items: dto.items.sorted(by: { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }).map { toStoryItem($0, storyCreatedAt: dto.createdAt) },
            isViewed: isViewed,
            audience: dto.audience,
            viewsCount: dto.viewsCount ?? 0,
            repliesCount: dto.repliesCount ?? 0,
            createdAt: createdAt,
            expiresAt: expiresAt
        )
    }

    static func toEntityList(_ dtos: [StoryDTO]) -> [Story] {
        dtos.map { toEntity($0) }
    }

    // MARK: - StoryItem

    private static func toStoryItem(_ dto: StoryItemDTO, storyCreatedAt: String?) -> StoryItem {
        let mediaType: StoryItem.MediaType = dto.type.uppercased() == "VIDEO" ? .video : .image

        let sticker: StoryStickerInfo?
        if let stickerType = dto.stickerType,
           let type = StoryStickerInfo.StickerType(rawValue: stickerType) {
            sticker = StoryStickerInfo(type: type, data: dto.stickerData)
        } else {
            sticker = nil
        }

        let createdAtDate: Date
        if let itemCreated = dto.createdAt, !itemCreated.isEmpty {
            createdAtDate = DateMapper.toDate(itemCreated)
        } else if let storyCreated = storyCreatedAt, !storyCreated.isEmpty {
            createdAtDate = DateMapper.toDate(storyCreated)
        } else {
            createdAtDate = .now
        }

        return StoryItem(
            id: dto.id,
            mediaURL: URL(string: dto.mediaUrl) ?? URL(string: "about:blank")!,
            thumbnailURL: dto.thumbnailUrl.flatMap { URL(string: $0) },
            type: mediaType,
            duration: dto.duration,
            sortOrder: dto.sortOrder ?? 0,
            createdAt: createdAtDate,
            sticker: sticker
        )
    }

    private static func toUserStory(_ dto: UserStoryDTO, fallbackId: String = "") -> User {
        let resolvedId = (dto.id.isEmpty ? fallbackId : dto.id)
        return User(
            id: resolvedId,
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
            isFollowing: false,
            isFollowedBy: false,
            isBlocked: false
        )
    }

    // MARK: - StoryReply

    static func toStoryReply(_ dto: StoryReplyDTO) -> StoryReply {
        let user = CommentMapper.toUser(dto.user)
        let reactions = dto.reactions?.map { toStoryReaction($0) } ?? []

        return StoryReply(
            id: dto.id,
            user: user,
            text: dto.text,
            createdAt: DateMapper.toDate(dto.createdAt),
            reactions: reactions
        )
    }

    static func toStoryReaction(_ dto: StoryReactionDTO) -> StoryReaction {
        return StoryReaction(
            id: dto.id,
            emoji: dto.emoji,
            userId: dto.userId
        )
    }

    static func toStoryRepliesResult(_ dto: StoryRepliesResultDTO) -> StoryRepliesResult {
        let replies = dto.replies.map { toStoryReply($0) }
        return StoryRepliesResult(
            replies: replies,
            isCurrentUserOwner: dto.isCurrentUserOwner,
            areRepliesEnabled: dto.areRepliesEnabled
        )
    }
}
