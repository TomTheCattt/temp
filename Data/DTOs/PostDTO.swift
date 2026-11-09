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
    let locationLat: String?
    let locationLng: String?
    let likesCount: Int
    let commentsCount: Int
    let isSponsored: Bool
    let createdAt: String
    let updatedAt: String?
    var author: PostUserDTO
    let mediaItems: [MediaItemDTO]
    let isLiked: Bool?
    let isSaved: Bool?
}

// MARK: - MediaItemDTO

nonisolated struct PostUserDTO: Decodable, Sendable {
    let id: String
    let username: String?
    let fullName: String?
    let isVerified: Bool?
    let isFollowing: Bool?
    let avatarUrl: String?
}

// MARK: - PostUserDTO

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
}

// MARK: - PostWrapperDTO

/// Wrapper for single post responses: `{ "post": {...} }` inside data envelope.
nonisolated struct PostWrapperDTO: Decodable, Sendable {
    let post: PostDTO
}

// MARK: - PaginatedPostsDTO

/// Wrapper for cursor-paginated post list responses.
/// BE returns: { items: [...], nextCursor: "2026-08-04T14:37:10.661Z" | null, hasMore: true }
nonisolated struct PaginatedPostsDTO: Decodable, Sendable {
    let items: [PostDTO]
    let nextCursor: String?
    let hasMore: Bool
}
