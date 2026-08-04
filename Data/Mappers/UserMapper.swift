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
            username: dto.username ?? "",
            fullName: dto.fullName ?? "",
            email: dto.email,
            phone: dto.phone,
            avatarURL: dto.avatarUrl.flatMap { URL(string: $0) },
            bio: dto.bio,
            website: dto.website,
            isVerified: dto.isVerified ?? false,
            isPrivate: dto.isPrivate ?? false,
            followersCount: dto.followersCount ?? 0,
            followingCount: dto.followingCount ?? 0,
            postsCount: dto.postsCount ?? 0,
            createdAt: dto.createdAt.map { DateMapper.toDate($0) } ?? .now,
            isFollowing: dto.isFollowing ?? false,
            isFollowedBy: dto.isFollowedBy ?? false,
            isBlocked: dto.isBlocked ?? false
        )
    }

    static func toEntityList(_ dtos: [UserDTO]) -> [User] {
        dtos.map { toEntity($0) }
    }
}
