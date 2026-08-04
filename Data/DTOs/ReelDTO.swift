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
}

// MARK: - ReelWrapperDTO

/// Wrapper for single reel response: `{ "reel": {...} }` inside data envelope.
nonisolated struct ReelWrapperDTO: Decodable, Sendable {
    let reel: ReelDTO
}

// MARK: - PaginatedReelsDTO

/// Wrapper for paginated reel list responses.
nonisolated struct PaginatedReelsDTO: Decodable, Sendable {
    let items: [ReelDTO]
    let page: Int
    let perPage: Int
    let total: Int
    let hasMore: Bool
}
