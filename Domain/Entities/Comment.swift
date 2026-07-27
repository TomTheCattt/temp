//
//  Comment.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - Comment

struct Comment: Identifiable, Hashable, Sendable {
    let id: String
    let postId: String
    let author: User
    let text: String
    let likesCount: Int
    let isLiked: Bool
    let replies: [Comment]
    let parentId: String? // nil = top-level comment
    let createdAt: Date
}
