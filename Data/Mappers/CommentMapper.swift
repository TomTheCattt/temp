//
//  CommentMapper.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - CommentMapper

nonisolated enum CommentMapper {

    static func toEntity(_ dto: CommentDTO) -> Comment {
        Comment(
            id: dto.id,
            postId: dto.postId,
            author: toAuthor(dto.author),
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

    // MARK: - Author Mapping

    /// Convert CommentAuthorDTO to User (public API for StoryMapper, etc.)
    static func toUser(_ dto: CommentAuthorDTO) -> User {
        User(
            id: dto.id,
            username: dto.username ?? "",
            fullName: dto.fullName ?? "",
            email: nil,
            phone: nil,
            avatarURL: dto.avatarUrl.flatMap { URL(string: $0) },
            bio: nil,
            website: nil,
            isVerified: dto.isVerified ?? false,
            isPrivate: false,
            followersCount: 0,
            followingCount: 0,
            postsCount: 0,
            createdAt: .now,
            isFollowing: dto.isFollowing ?? false,
            isFollowedBy: false,
            isBlocked: false
        )
    }

    private static func toAuthor(_ dto: CommentAuthorDTO) -> User {
        toUser(dto)
    }
}
