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
    let audioName: String?
    let audioArtist: String?
    let audioCoverUrl: String?
    let isOriginalAudio: Bool?
    let duration: Double
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let viewsCount: Int
    let createdAt: String
    let author: UserDTO
    let isLiked: Bool?
    let isSaved: Bool?
}

// MARK: - ReelWrapperDTO

/// Wrapper for single reel response: `{ "reel": {...} }` inside data envelope.
nonisolated struct ReelWrapperDTO: Decodable, Sendable {
    let reel: ReelDTO
}

// MARK: - PaginatedReelsDTO

/// Wrapper for cursor-paginated reel list responses.
/// BE returns: { items: [...], nextCursor: "2026-08-04T14:37:10.661Z" | null, hasMore: true }
nonisolated struct PaginatedReelsDTO: Decodable, Sendable {
    let items: [ReelDTO]
    let nextCursor: String?
    let hasMore: Bool
}
