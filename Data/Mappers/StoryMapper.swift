//
//  StoryMapper.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - StoryMapper

enum StoryMapper {

    static func toEntity(_ dto: StoryDTO) -> Story {
        // Determine author: from nested object or create minimal from authorId
        let author: User
        if let authorDTO = dto.author {
            author = UserMapper.toEntity(authorDTO)
        } else {
            author = User(
                id: dto.authorId,
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

        // isViewed: if views array is non-empty, current user has viewed
        let isViewed = !(dto.views ?? []).isEmpty

        return Story(
            id: dto.id,
            author: author,
            items: dto.items.sorted(by: { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }).map { toStoryItem($0) },
            isViewed: isViewed,
            createdAt: DateMapper.toDate(dto.createdAt),
            expiresAt: DateMapper.toDate(dto.expiresAt)
        )
    }

    static func toEntityList(_ dtos: [StoryDTO]) -> [Story] {
        dtos.map { toEntity($0) }
    }

    // MARK: - StoryItem

    private static func toStoryItem(_ dto: StoryItemDTO) -> StoryItem {
        let mediaType: StoryItem.MediaType = dto.type.uppercased() == "VIDEO" ? .video : .image

        let sticker: StoryStickerInfo?
        if let stickerType = dto.stickerType,
           let type = StoryStickerInfo.StickerType(rawValue: stickerType) {
            sticker = StoryStickerInfo(type: type, data: dto.stickerData)
        } else {
            sticker = nil
        }

        return StoryItem(
            id: dto.id,
            mediaURL: URL(string: dto.mediaUrl) ?? URL(string: "about:blank")!,
            type: mediaType,
            duration: dto.duration,
            createdAt: DateMapper.toDate(dto.createdAt),
            sticker: sticker
        )
    }
}
