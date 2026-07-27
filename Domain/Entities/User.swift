//
//  User.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - User

struct User: Identifiable, Hashable, Sendable {
    let id: String
    let username: String
    let fullName: String
    let email: String?
    let phone: String?
    let avatarURL: URL?
    let bio: String?
    let website: String?
    let isVerified: Bool
    let isPrivate: Bool
    let followersCount: Int
    let followingCount: Int
    let postsCount: Int
    let createdAt: Date

    // Relationship states (relative to current user)
    var isFollowing: Bool
    var isFollowedBy: Bool
    var isBlocked: Bool
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
