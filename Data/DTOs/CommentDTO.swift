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
    let author: UserDTO
    let replies: [CommentDTO]?
    let isLiked: Bool?
}

// MARK: - CommentWrapperDTO

/// Wrapper for single comment responses: `{ "comment": {...} }` inside data envelope.
nonisolated struct CommentWrapperDTO: Decodable, Sendable {
    let comment: CommentDTO
}

// MARK: - PaginatedCommentsDTO

/// Wrapper for paginated comment list responses.
nonisolated struct PaginatedCommentsDTO: Decodable, Sendable {
    let items: [CommentDTO]
    let page: Int
    let perPage: Int
    let total: Int
    let hasMore: Bool
}
