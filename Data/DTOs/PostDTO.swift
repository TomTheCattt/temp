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
    let isSponsored: Bool
    let createdAt: String
    let updatedAt: String?
    let author: UserDTO
    let mediaItems: [MediaItemDTO]
    let isLiked: Bool?
    let isSaved: Bool?
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
}

// MARK: - PostWrapperDTO

/// Wrapper for single post responses: `{ "post": {...} }` inside data envelope.
nonisolated struct PostWrapperDTO: Decodable, Sendable {
    let post: PostDTO
}

// MARK: - PaginatedPostsDTO

/// Wrapper for paginated post list responses.
nonisolated struct PaginatedPostsDTO: Decodable, Sendable {
    let items: [PostDTO]
    let page: Int
    let perPage: Int
    let total: Int
    let hasMore: Bool
}
