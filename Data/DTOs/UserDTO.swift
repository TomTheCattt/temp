//
//  UserDTO.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - UserDTO

/// API response model for User.
nonisolated struct UserDTO: Decodable, Sendable {
    let id: String
    let username: String
    let fullName: String
    let email: String?
    let phone: String?
    let avatarUrl: String?
    let bio: String?
    let website: String?
    let isVerified: Bool
    let isPrivate: Bool
    let followersCount: Int
    let followingCount: Int
    let postsCount: Int
    let createdAt: String
    let isFollowing: Bool?
    let isFollowedBy: Bool?
    let isBlocked: Bool?
}
