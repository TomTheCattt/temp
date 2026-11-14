//
//  User.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - User

nonisolated struct User: Identifiable, Hashable, Sendable, Codable {
    let id: String
    let username: String
    let fullName: String
    let email: String?
    let phone: String?
    let avatarURL: URL?
    let avatarThumbURL: URL?
    let bio: String?
    let website: String?
    let isVerified: Bool
    let isPrivate: Bool
    let isBusiness: Bool
    let businessCategory: String?
    let followersCount: Int
    let followingCount: Int
    let postsCount: Int
    let reelsCount: Int
    let createdAt: Date

    // Relationship states (relative to current user)
    var isFollowing: Bool
    var isFollowedBy: Bool
    var isBlocked: Bool

    init(
        id: String,
        username: String,
        fullName: String,
        email: String? = nil,
        phone: String? = nil,
        avatarURL: URL? = nil,
        avatarThumbURL: URL? = nil,
        bio: String? = nil,
        website: String? = nil,
        isVerified: Bool = false,
        isPrivate: Bool = false,
        isBusiness: Bool = false,
        businessCategory: String? = nil,
        followersCount: Int = 0,
        followingCount: Int = 0,
        postsCount: Int = 0,
        reelsCount: Int = 0,
        createdAt: Date = .now,
        isFollowing: Bool = false,
        isFollowedBy: Bool = false,
        isBlocked: Bool = false
    ) {
        self.id = id
        self.username = username
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.avatarURL = avatarURL
        self.avatarThumbURL = avatarThumbURL ?? avatarURL
        self.bio = bio
        self.website = website
        self.isVerified = isVerified
        self.isPrivate = isPrivate
        self.isBusiness = isBusiness
        self.businessCategory = businessCategory
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.postsCount = postsCount
        self.reelsCount = reelsCount
        self.createdAt = createdAt
        self.isFollowing = isFollowing
        self.isFollowedBy = isFollowedBy
        self.isBlocked = isBlocked
    }
}

// MARK: - User Defaults

extension User {
    static let empty = User(
        id: "",
        username: "",
        fullName: "",
        email: nil,
        phone: nil,
        avatarURL: nil,
        bio: nil,
        website: nil,
        isVerified: false,
        isPrivate: false,
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
        createdAt: .now,
        isFollowing: false,
        isFollowedBy: false,
        isBlocked: false
    )
}
