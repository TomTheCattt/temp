//
//  PostDTO.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - PostDTO

/// API response model for Post. Matches BE response format.
nonisolated struct PostDTO: Decodable, Sendable {
    let id: String
    let authorId: String
    let caption: String?
    let locationName: String?
    let locationLat: Double?
    let locationLng: Double?
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let savesCount: Int
    let viewsCount: Int
    let isSponsored: Bool
    let sponsorUserId: String?
    let audience: String? // "PUBLIC" | "FOLLOWERS" | "CLOSE_FRIENDS"
    let closeFriendsOnly: Bool
    let createdAt: String
    let updatedAt: String?
    var author: PostUserDTO
    let mediaItems: [MediaItemDTO]
    let isLiked: Bool?
    let isSaved: Bool?

    enum CodingKeys: String, CodingKey {
        case id, authorId, caption, locationName, locationLat, locationLng
        case likesCount, commentsCount, sharesCount, savesCount, viewsCount
        case isSponsored, sponsorUserId, audience, closeFriendsOnly
        case createdAt, updatedAt, author, mediaItems, isLiked, isSaved
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        authorId = try container.decodeIfPresent(String.self, forKey: .authorId) ?? ""
        caption = try container.decodeIfPresent(String.self, forKey: .caption)
        locationName = try container.decodeIfPresent(String.self, forKey: .locationName)

        // Flexible decoding for locationLat: Double, String, or Int (supports Postgres Decimal/Numeric)
        if let dbl = try? container.decodeIfPresent(Double.self, forKey: .locationLat) {
            locationLat = dbl
        } else if let str = try? container.decodeIfPresent(String.self, forKey: .locationLat), let parsed = Double(str) {
            locationLat = parsed
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .locationLat) {
            locationLat = Double(intVal)
        } else {
            locationLat = nil
        }

        // Flexible decoding for locationLng: Double, String, or Int (supports Postgres Decimal/Numeric)
        if let dbl = try? container.decodeIfPresent(Double.self, forKey: .locationLng) {
            locationLng = dbl
        } else if let str = try? container.decodeIfPresent(String.self, forKey: .locationLng), let parsed = Double(str) {
            locationLng = parsed
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .locationLng) {
            locationLng = Double(intVal)
        } else {
            locationLng = nil
        }

        likesCount = (try? container.decodeIfPresent(Int.self, forKey: .likesCount)) ?? 0
        commentsCount = (try? container.decodeIfPresent(Int.self, forKey: .commentsCount)) ?? 0
        sharesCount = (try? container.decodeIfPresent(Int.self, forKey: .sharesCount)) ?? 0
        savesCount = (try? container.decodeIfPresent(Int.self, forKey: .savesCount)) ?? 0
        viewsCount = (try? container.decodeIfPresent(Int.self, forKey: .viewsCount)) ?? 0
        isSponsored = (try? container.decodeIfPresent(Bool.self, forKey: .isSponsored)) ?? false
        sponsorUserId = try container.decodeIfPresent(String.self, forKey: .sponsorUserId)
        audience = try container.decodeIfPresent(String.self, forKey: .audience)
        closeFriendsOnly = (try? container.decodeIfPresent(Bool.self, forKey: .closeFriendsOnly)) ?? false
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        author = try container.decode(PostUserDTO.self, forKey: .author)
        mediaItems = (try? container.decodeIfPresent([MediaItemDTO].self, forKey: .mediaItems)) ?? []
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked)
        isSaved = try container.decodeIfPresent(Bool.self, forKey: .isSaved)
    }
}

// MARK: - PostUserDTO

nonisolated struct PostUserDTO: Decodable, Sendable {
    let id: String
    let username: String?
    let fullName: String?
    let isVerified: Bool?
    let isFollowing: Bool?
    let isPrivate: Bool?
    let avatarUrl: String?
}

// MARK: - MediaItemDTO

nonisolated struct MediaItemDTO: Decodable, Sendable {
    let id: String
    let postId: String?
    let url: String
    let thumbnailUrl: String?
    let type: String        // "IMAGE" | "VIDEO" (uppercase from BE)
    let width: Int?
    let height: Int?
    let duration: Double?
    let sortOrder: Int?

    enum CodingKeys: String, CodingKey {
        case id, postId, url, thumbnailUrl, type, width, height, duration, sortOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        postId = try container.decodeIfPresent(String.self, forKey: .postId)
        url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "IMAGE"
        width = try container.decodeIfPresent(Int.self, forKey: .width)
        height = try container.decodeIfPresent(Int.self, forKey: .height)

        // Flexible decoding for duration: Double, String, or Int
        if let dbl = try? container.decodeIfPresent(Double.self, forKey: .duration) {
            duration = dbl
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .duration) {
            duration = Double(intVal)
        } else if let str = try? container.decodeIfPresent(String.self, forKey: .duration), let parsed = Double(str) {
            duration = parsed
        } else {
            duration = nil
        }

        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder)
    }
}

// MARK: - PostWrapperDTO

/// Wrapper for single post responses: `{ "post": {...} }` inside data envelope.
nonisolated struct PostWrapperDTO: Decodable, Sendable {
    let post: PostDTO
}

// MARK: - PaginatedPostsDTO

/// Wrapper for cursor-paginated post list responses (feeds).
/// BE returns: { items: [...], nextCursor: "2026-08-04T14:37:10.661Z" | null, hasMore: true }
/// For offset-paginated responses (user posts): { items: [...], page: 1, perPage: 20, total: 100, hasMore: true }
nonisolated struct PaginatedPostsDTO: Decodable, Sendable {
    let items: [PostDTO]
    let nextCursor: String?
    let hasMore: Bool
    // Offset pagination fields
    let page: Int?
    let perPage: Int?
    let total: Int?
}
