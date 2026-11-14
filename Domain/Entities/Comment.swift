//
//  Comment.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - Comment

nonisolated struct Comment: Identifiable, Hashable, Sendable {
    let id: String
    let commentableType: CommentableType
    let commentableId: String
    let postId: String
    let author: User
    let text: String
    let likesCount: Int
    let repliesCount: Int
    let isLiked: Bool
    let replies: [Comment]
    let parentId: String? // nil = top-level comment
    let createdAt: Date

    init(
        id: String,
        commentableType: CommentableType = .post,
        commentableId: String? = nil,
        postId: String? = nil,
        author: User,
        text: String,
        likesCount: Int,
        repliesCount: Int = 0,
        isLiked: Bool,
        replies: [Comment] = [],
        parentId: String? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.commentableType = commentableType
        let resolvedId = commentableId ?? postId ?? ""
        self.commentableId = resolvedId
        self.postId = postId ?? resolvedId
        self.author = author
        self.text = text
        self.likesCount = likesCount
        self.repliesCount = repliesCount
        self.isLiked = isLiked
        self.replies = replies
        self.parentId = parentId
        self.createdAt = createdAt
    }
}
