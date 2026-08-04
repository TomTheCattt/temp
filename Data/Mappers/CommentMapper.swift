//
//  CommentMapper.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - CommentMapper

enum CommentMapper {

    static func toEntity(_ dto: CommentDTO) -> Comment {
        Comment(
            id: dto.id,
            postId: dto.postId,
            author: UserMapper.toEntity(dto.author),
            text: dto.text,
            likesCount: dto.likesCount,
            isLiked: dto.isLiked ?? false,
            replies: dto.replies?.map { toEntity($0) } ?? [],
            parentId: dto.parentId,
            createdAt: DateMapper.toDate(dto.createdAt)
        )
    }

    static func toEntityList(_ dtos: [CommentDTO]) -> [Comment] {
        dtos.map { toEntity($0) }
    }
}
