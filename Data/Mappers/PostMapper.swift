//
//  PostMapper.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - PostMapper

enum PostMapper {

    static func toEntity(_ dto: PostDTO) -> Post {
        Post(
            id: dto.id,
            author: UserMapper.toEntity(dto.author),
            caption: dto.caption,
            mediaItems: dto.mediaItems.map { toMediaItem($0) },
            location: dto.location.map { toLocation($0) },
            likesCount: dto.likesCount,
            commentsCount: dto.commentsCount,
            createdAt: DateMapper.toDate(dto.createdAt),
            isLiked: dto.isLiked,
            isSaved: dto.isSaved,
            isSponsored: dto.isSponsored
        )
    }

    static func toEntityList(_ dtos: [PostDTO]) -> [Post] {
        dtos.map { toEntity($0) }
    }

    // MARK: - MediaItem

    private static func toMediaItem(_ dto: MediaItemDTO) -> MediaItem {
        MediaItem(
            id: dto.id,
            url: URL(string: dto.url)!,
            thumbnailURL: dto.thumbnailUrl.flatMap { URL(string: $0) },
            type: dto.type == "video" ? .video : .image,
            width: dto.width,
            height: dto.height,
            duration: dto.duration
        )
    }

    // MARK: - Location

    private static func toLocation(_ dto: PostLocationDTO) -> PostLocation {
        PostLocation(
            name: dto.name,
            latitude: dto.latitude,
            longitude: dto.longitude
        )
    }
}
