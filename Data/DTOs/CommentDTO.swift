//
//  CommentDTO.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - CommentDTO

/// API response model for Comment.
nonisolated struct CommentDTO: Decodable, Sendable {
    let id: String
    let postId: String
    let author: UserDTO
    let text: String
    let likesCount: Int
    let isLiked: Bool
    let replies: [CommentDTO]?
    let parentId: String?
    let createdAt: String
}
