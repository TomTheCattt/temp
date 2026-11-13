//
//  CommentDTO.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - CommentDTO

/// API response model for Comment. Matches BE response format.
nonisolated struct CommentDTO: Decodable, Sendable {
    let id: String
    let postId: String
    let authorId: String
    let text: String
    let parentId: String?
    let likesCount: Int
    let createdAt: String
    let author: CommentAuthorDTO
    let replies: [CommentDTO]?
    let isLiked: Bool?
}

// MARK: - CommentWrapperDTO

/// Wrapper for single comment responses: `{ "comment": {...} }` inside data envelope.
nonisolated struct CommentWrapperDTO: Decodable, Sendable {
    let comment: CommentDTO
}

// MARK: - PaginatedCommentsDTO

/// Wrapper for offset-paginated comment list responses.
/// BE returns: { items: [...], page: 1, perPage: 20, total: 100, hasMore: true }
nonisolated struct PaginatedCommentsDTO: Decodable, Sendable {
    let items: [CommentDTO]
    let page: Int
    let perPage: Int
    let total: Int
    let hasMore: Bool
}

// MARK: - CommentAuthorDTO

/// Lightweight user object returned in comment contexts.
/// BE returns: id, username, fullName, avatarUrl, isVerified, isFollowing
nonisolated struct CommentAuthorDTO: Decodable, Sendable {
    let id: String
    let username: String?
    let fullName: String?
    let avatarUrl: String?
    let isVerified: Bool?
    let isFollowing: Bool?
}
