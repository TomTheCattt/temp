//
//  SDCachedUser.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation
import SwiftData

// MARK: - SDCachedUser

/// SwiftData model for caching User profiles offline.
@Model
final class SDCachedUser {
    @Attribute(.unique) var id: String
    var username: String
    var fullName: String
    var email: String?
    var phone: String?
    var avatarURL: String?
    var bio: String?
    var website: String?
    var isVerified: Bool
    var isPrivate: Bool
    var followersCount: Int
    var followingCount: Int
    var postsCount: Int
    var createdAt: Date
    var isFollowing: Bool
    var isFollowedBy: Bool
    var isBlocked: Bool

    /// When this cache entry was last updated.
    var cachedAt: Date

    init(
        id: String,
        username: String,
        fullName: String,
        email: String? = nil,
        phone: String? = nil,
        avatarURL: String? = nil,
        bio: String? = nil,
        website: String? = nil,
        isVerified: Bool = false,
        isPrivate: Bool = false,
        followersCount: Int = 0,
        followingCount: Int = 0,
        postsCount: Int = 0,
        createdAt: Date = .now,
        isFollowing: Bool = false,
        isFollowedBy: Bool = false,
        isBlocked: Bool = false,
        cachedAt: Date = .now
    ) {
        self.id = id
        self.username = username
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.avatarURL = avatarURL
        self.bio = bio
        self.website = website
        self.isVerified = isVerified
        self.isPrivate = isPrivate
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.postsCount = postsCount
        self.createdAt = createdAt
        self.isFollowing = isFollowing
        self.isFollowedBy = isFollowedBy
        self.isBlocked = isBlocked
        self.cachedAt = cachedAt
    }
}

// MARK: - Entity Mapping

extension SDCachedUser {

    /// Convert domain entity to SwiftData model.
    convenience init(from user: User) {
        self.init(
            id: user.id,
            username: user.username,
            fullName: user.fullName,
            email: user.email,
            phone: user.phone,
            avatarURL: user.avatarURL?.absoluteString,
            bio: user.bio,
            website: user.website,
            isVerified: user.isVerified,
            isPrivate: user.isPrivate,
            followersCount: user.followersCount,
            followingCount: user.followingCount,
            postsCount: user.postsCount,
            createdAt: user.createdAt,
            isFollowing: user.isFollowing,
            isFollowedBy: user.isFollowedBy,
            isBlocked: user.isBlocked,
            cachedAt: .now
        )
    }

    /// Convert SwiftData model back to domain entity.
    func toEntity() -> User {
        User(
            id: id,
            username: username,
            fullName: fullName,
            email: email,
            phone: phone,
            avatarURL: avatarURL.flatMap { URL(string: $0) },
            bio: bio,
            website: website,
            isVerified: isVerified,
            isPrivate: isPrivate,
            followersCount: followersCount,
            followingCount: followingCount,
            postsCount: postsCount,
            createdAt: createdAt,
            isFollowing: isFollowing,
            isFollowedBy: isFollowedBy,
            isBlocked: isBlocked
        )
    }
}
