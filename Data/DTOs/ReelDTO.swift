//
//  ReelDTO.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - ReelDTO

/// API response model for Reel. Matches BE response format.
/// Audio fields are flat (not nested object) per BE design.
nonisolated struct ReelDTO: Decodable, Sendable {
    let id: String
    let authorId: String
    let videoUrl: String
    let thumbnailUrl: String?
    let caption: String?
    let audioId: String?
    let audioName: String?
    let audioArtist: String?
    let audioCoverUrl: String?
    let isOriginalAudio: Bool?
    let duration: Double?
    let likesCount: Int?
    let commentsCount: Int?
    let sharesCount: Int?
    let savesCount: Int?
    let viewsCount: Int?
    let allowRemix: Bool?
    let allowDownload: Bool?
    let createdAt: String
    let author: ReelAuthorDTO
    let isLiked: Bool?
    let isSaved: Bool?

    enum CodingKeys: String, CodingKey {
        case id, authorId, videoUrl, thumbnailUrl, caption
        case audioId, audioName, audioArtist, audioCoverUrl, isOriginalAudio
        case duration, likesCount, commentsCount, sharesCount, savesCount, viewsCount
        case allowRemix, allowDownload, createdAt, author, isLiked, isSaved
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        authorId = try container.decodeIfPresent(String.self, forKey: .authorId) ?? ""
        videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl) ?? ""
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        caption = try container.decodeIfPresent(String.self, forKey: .caption)
        audioId = try container.decodeIfPresent(String.self, forKey: .audioId)
        audioName = try container.decodeIfPresent(String.self, forKey: .audioName)
        audioArtist = try container.decodeIfPresent(String.self, forKey: .audioArtist)
        audioCoverUrl = try container.decodeIfPresent(String.self, forKey: .audioCoverUrl)
        isOriginalAudio = try container.decodeIfPresent(Bool.self, forKey: .isOriginalAudio)

        // Flexible duration decoding: supports Double, Int, or String
        if let dbl = try? container.decodeIfPresent(Double.self, forKey: .duration) {
            duration = dbl
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .duration) {
            duration = Double(intVal)
        } else if let str = try? container.decodeIfPresent(String.self, forKey: .duration), let parsed = Double(str) {
            duration = parsed
        } else {
            duration = nil
        }

        likesCount = try container.decodeIfPresent(Int.self, forKey: .likesCount)
        commentsCount = try container.decodeIfPresent(Int.self, forKey: .commentsCount)
        sharesCount = try container.decodeIfPresent(Int.self, forKey: .sharesCount)
        savesCount = try container.decodeIfPresent(Int.self, forKey: .savesCount)
        viewsCount = try container.decodeIfPresent(Int.self, forKey: .viewsCount)
        allowRemix = try container.decodeIfPresent(Bool.self, forKey: .allowRemix)
        allowDownload = try container.decodeIfPresent(Bool.self, forKey: .allowDownload)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        author = try container.decode(ReelAuthorDTO.self, forKey: .author)
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked)
        isSaved = try container.decodeIfPresent(Bool.self, forKey: .isSaved)
    }
}

// MARK: - ReelAuthorDTO

/// Lightweight user object returned in reel contexts.
/// BE returns: id, username, fullName, avatarUrl, isVerified, isFollowing
nonisolated struct ReelAuthorDTO: Decodable, Sendable {
    let id: String
    let username: String?
    let fullName: String?
    let avatarUrl: String?
    let isVerified: Bool?
    let isFollowing: Bool?
}

// MARK: - ReelWrapperDTO

/// Wrapper for single reel response: `{ "reel": {...} }` inside data envelope.
nonisolated struct ReelWrapperDTO: Decodable, Sendable {
    let reel: ReelDTO
}

// MARK: - PaginatedReelsDTO

/// Wrapper for paginated reel list responses.
/// For cursor-based (feed): { items: [...], nextCursor: "2026-08-04T14:37:10.661Z" | null, hasMore: true }
/// For offset-based (user reels): { items: [...], page: 1, perPage: 20, total: 100, hasMore: true }
nonisolated struct PaginatedReelsDTO: Decodable, Sendable {
    let items: [ReelDTO]
    let nextCursor: String?
    let hasMore: Bool
    // Offset pagination fields
    let page: Int?
    let perPage: Int?
    let total: Int?
}