//
//  UserDTO.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - UserDTO

/// Full user response from BE (login, register, /users/me, /users/:id).
/// All fields are optional to handle both full and partial user objects from BE.
nonisolated struct UserDTO: Decodable, Sendable {
    let id: String
    let firebaseUid: String?
    let username: String?
    let fullName: String?
    let email: String?
    let phone: String?
    let avatarUrl: String?
    let bio: String?
    let website: String?
    let isVerified: Bool?
    let isPrivate: Bool?
    let followersCount: Int?
    let followingCount: Int?
    let postsCount: Int?
    let createdAt: String?
    let updatedAt: String?
    // Relationship states (only present in profile endpoints)
    let isFollowing: Bool?
    let isFollowedBy: Bool?
    let isBlocked: Bool?
}

// MARK: - UserWrapperDTO

/// Wrapper for endpoints that return `{ "user": {...} }` inside the data envelope.
nonisolated struct UserWrapperDTO: Decodable, Sendable {
    let user: UserDTO
}

// MARK: - PaginatedUsersDTO

/// Wrapper for paginated user list responses.
nonisolated struct PaginatedUsersDTO: Decodable, Sendable {
    let items: [UserDTO]
    let page: Int
    let perPage: Int
    let total: Int
    let hasMore: Bool
}
