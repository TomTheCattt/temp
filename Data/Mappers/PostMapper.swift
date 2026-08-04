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
            mediaItems: dto.mediaItems.sorted(by: { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }).map { toMediaItem($0) },
            location: toLocation(name: dto.locationName, lat: dto.locationLat, lng: dto.locationLng),
            likesCount: dto.likesCount,
            commentsCount: dto.commentsCount,
            createdAt: DateMapper.toDate(dto.createdAt),
            isLiked: dto.isLiked ?? false,
            isSaved: dto.isSaved ?? false,
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
            url: URL(string: dto.url) ?? URL(string: "about:blank")!,
            thumbnailURL: dto.thumbnailUrl.flatMap { URL(string: $0) },
            type: dto.type.uppercased() == "VIDEO" ? .video : .image,
            width: dto.width,
            height: dto.height,
            duration: dto.duration
        )
    }

    // MARK: - Location

    private static func toLocation(name: String?, lat: Double?, lng: Double?) -> PostLocation? {
        guard let name else { return nil }
        return PostLocation(
            name: name,
            latitude: lat,
            longitude: lng
        )
    }
}
