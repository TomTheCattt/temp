//
//  UserMapper.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - UserMapper

enum UserMapper {

    static func toEntity(_ dto: UserDTO) -> User {
        User(
            id: dto.id,
            username: dto.username,
            fullName: dto.fullName,
            email: dto.email,
            phone: dto.phone,
            avatarURL: URL(string: dto.avatarUrl ?? ""),
            bio: dto.bio,
            website: dto.website,
            isVerified: dto.isVerified,
            isPrivate: dto.isPrivate,
            followersCount: dto.followersCount,
            followingCount: dto.followingCount,
            postsCount: dto.postsCount,
            createdAt: DateMapper.toDate(dto.createdAt),
            isFollowing: dto.isFollowing ?? false,
            isFollowedBy: dto.isFollowedBy ?? false,
            isBlocked: dto.isBlocked ?? false
        )
    }

    static func toEntityList(_ dtos: [UserDTO]) -> [User] {
        dtos.map { toEntity($0) }
    }
}
