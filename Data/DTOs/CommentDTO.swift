//
//  CommentDTO.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - CommentDTO

/// API response model for Comment. Matches BE response format.
nonisolated struct CommentDTO: Decodable, Sendable {
    let id: String
    let commentableType: String?
    let commentableId: String?
    let postId: String?
    let authorId: String?
    let text: String
    let parentId: String?
    let likesCount: Int
    let repliesCount: Int?
    let createdAt: String
    let author: CommentAuthorDTO
    let replies: [CommentDTO]?
    let isLiked: Bool?

    enum CodingKeys: String, CodingKey {
        case id, commentableType, commentableId, postId, authorId, text, parentId, likesCount, repliesCount, createdAt, author, user, replies, isLiked
    }

    init(
        id: String,
        commentableType: String? = nil,
        commentableId: String? = nil,
        postId: String? = nil,
        authorId: String? = nil,
        text: String = "",
        parentId: String? = nil,
        likesCount: Int = 0,
        repliesCount: Int? = nil,
        createdAt: String = "",
        author: CommentAuthorDTO,
        replies: [CommentDTO]? = nil,
        isLiked: Bool? = nil
    ) {
        self.id = id
        self.commentableType = commentableType
        self.commentableId = commentableId
        self.postId = postId
        self.authorId = authorId
        self.text = text
        self.parentId = parentId
        self.likesCount = likesCount
        self.repliesCount = repliesCount
        self.createdAt = createdAt
        self.author = author
        self.replies = replies
        self.isLiked = isLiked
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        commentableType = try container.decodeIfPresent(String.self, forKey: .commentableType)
        commentableId = try container.decodeIfPresent(String.self, forKey: .commentableId)
        postId = try container.decodeIfPresent(String.self, forKey: .postId)
        authorId = try container.decodeIfPresent(String.self, forKey: .authorId)
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        likesCount = try container.decodeIfPresent(Int.self, forKey: .likesCount) ?? 0
        repliesCount = try container.decodeIfPresent(Int.self, forKey: .repliesCount)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""

        if let authorObj = try? container.decode(CommentAuthorDTO.self, forKey: .author) {
            author = authorObj
        } else if let userObj = try? container.decode(CommentAuthorDTO.self, forKey: .user) {
            author = userObj
        } else {
            author = CommentAuthorDTO(
                id: authorId ?? "",
                username: nil,
                fullName: nil,
                avatarUrl: nil,
                isVerified: nil,
                isFollowing: nil
            )
        }

        replies = try container.decodeIfPresent([CommentDTO].self, forKey: .replies)
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked)
    }

    var resolvedCommentableId: String {
        commentableId ?? postId ?? ""
    }

    var resolvedCommentableType: CommentableType {
        if let typeStr = commentableType?.uppercased(), let type = CommentableType(rawValue: typeStr) {
            return type
        }
        return .post
    }
}

// MARK: - CommentWrapperDTO

/// Wrapper for single comment responses: `{ "comment": {...} }` inside data envelope.
nonisolated struct CommentWrapperDTO: Decodable, Sendable {
    let comment: CommentDTO
}

// MARK: - PaginatedCommentsDTO

/// API response model for Paginated Comments.
/// Polymorphically supports both Backend v2.0 Cursor pagination (`{ items, nextCursor, hasMore }`)
/// and Offset pagination (`{ items, page, perPage, total, hasMore }`).
nonisolated struct PaginatedCommentsDTO: Decodable, Sendable {
    let items: [CommentDTO]
    let nextCursor: String?
    let hasMore: Bool
    let page: Int
    let perPage: Int
    let total: Int

    enum CodingKeys: String, CodingKey {
        case items, nextCursor, hasMore, page, perPage, total
    }

    init(
        items: [CommentDTO] = [],
        nextCursor: String? = nil,
        hasMore: Bool = false,
        page: Int = 1,
        perPage: Int = 20,
        total: Int = 0
    ) {
        self.items = items
        self.nextCursor = nextCursor
        self.hasMore = hasMore
        self.page = page
        self.perPage = perPage
        self.total = total
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decodeIfPresent([CommentDTO].self, forKey: .items) ?? []
        nextCursor = try container.decodeIfPresent(String.self, forKey: .nextCursor)
        hasMore = try container.decodeIfPresent(Bool.self, forKey: .hasMore) ?? false

        page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 1
        perPage = try container.decodeIfPresent(Int.self, forKey: .perPage) ?? 20
        total = try container.decodeIfPresent(Int.self, forKey: .total) ?? items.count
    }
}

// MARK: - CommentAuthorDTO

/// Lightweight user object returned in comment contexts.
/// BE returns: id, username, fullName, avatarUrl, isVerified, isFollowing
nonisolated struct CommentAuthorDTO: Decodable, Sendable {
    let id: String
    let username: String?
    let fullName: String?
    let avatarUrl: String?
    let isVerified: Bool?
    let isFollowing: Bool?
}
