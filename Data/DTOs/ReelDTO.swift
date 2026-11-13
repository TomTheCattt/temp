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
    let duration: String?
    let likesCount: Int?
    let commentsCount: Int?
    let sharesCount: Int?
    let viewsCount: Int?
    let createdAt: String
    let author: ReelAuthorDTO
    let isLiked: Bool?
    let isSaved: Bool?
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