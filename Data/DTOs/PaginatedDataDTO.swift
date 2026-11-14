//
//  PaginatedDataDTO.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//  Generic Pagination and Author Summary matching Backend v2.0
//

import Foundation

// MARK: - 1. Phân trang dạng Cursor (Feed, Comments, Messages)

nonisolated struct CursorPaginatedData<T: Decodable & Sendable>: Decodable, Sendable {
    let items: [T]
    let nextCursor: String?
    let hasMore: Bool
}

// MARK: - 2. Phân trang dạng Page/Offset (Followers, Following, Search)

nonisolated struct OffsetPaginatedData<T: Decodable & Sendable>: Decodable, Sendable {
    let items: [T]
    let page: Int
    let perPage: Int
    let total: Int
    let hasMore: Bool
}

// MARK: - UserAuthorSummaryDTO

/// Standardized lightweight user summary returned across Feed, Reels, Stories, Comments, Notifications, and DMs.
nonisolated struct UserAuthorSummaryDTO: Decodable, Sendable, Identifiable {
    let id: String
    let username: String?
    let fullName: String?
    let avatarUrl: String?
    let isVerified: Bool?
    var isFollowing: Bool?
    let isPrivate: Bool?

    var user: User {
        User(
            id: id,
            username: username ?? "",
            fullName: fullName ?? "",
            email: nil,
            phone: nil,
            avatarURL: avatarUrl.flatMap { URL(string: $0) },
            bio: nil,
            website: nil,
            isVerified: isVerified ?? false,
            isPrivate: isPrivate ?? false,
            followersCount: 0,
            followingCount: 0,
            postsCount: 0,
            createdAt: .now,
            isFollowing: isFollowing ?? false,
            isFollowedBy: false,
            isBlocked: false
        )
    }
}
