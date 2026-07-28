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
        Story(
            id: dto.id,
            author: UserMapper.toEntity(dto.author),
            items: dto.items.map { toStoryItem($0) },
            isViewed: dto.isViewed,
            createdAt: DateMapper.toDate(dto.createdAt),
            expiresAt: DateMapper.toDate(dto.expiresAt)
        )
    }

    static func toEntityList(_ dtos: [StoryDTO]) -> [Story] {
        dtos.map { toEntity($0) }
    }

    // MARK: - StoryItem

    private static func toStoryItem(_ dto: StoryItemDTO) -> StoryItem {
        StoryItem(
            id: dto.id,
            mediaURL: URL(string: dto.mediaUrl)!,
            type: dto.type == "video" ? .video : .image,
            duration: dto.duration,
            createdAt: DateMapper.toDate(dto.createdAt),
            sticker: dto.sticker.map { toSticker($0) }
        )
    }

    // MARK: - Sticker

    private static func toSticker(_ dto: StoryStickerDTO) -> StoryStickerInfo {
        let stickerType: StoryStickerInfo.StickerType
        switch dto.type {
        case "mention":  stickerType = .mention
        case "hashtag":  stickerType = .hashtag
        case "location": stickerType = .location
        case "poll":     stickerType = .poll
        case "question": stickerType = .question
        case "link":     stickerType = .link
        case "music":    stickerType = .music
        default:         stickerType = .mention
        }
        return StoryStickerInfo(type: stickerType, data: dto.data)
    }
}
