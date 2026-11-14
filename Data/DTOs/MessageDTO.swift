//
//  MessageDTO.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - ConversationDTO

/// API response model for Conversation. Matches BE response format.
nonisolated struct ConversationDTO: Decodable, Sendable {
    let id: String
    let isGroup: Bool
    let groupName: String?
    let groupAvatar: String?
    let groupAvatarUrl: String?
    let lastMessageText: String?
    let lastMessageAt: String?
    let createdAt: String
    let updatedAt: String
    let members: [ConversationMemberDTO]
    let lastMessage: MessageDTO?
    let lastReadAt: String?
    let isMuted: Bool?
    let unreadCount: Int?

    var resolvedGroupAvatarUrl: String? {
        groupAvatarUrl ?? groupAvatar
    }
}

// MARK: - ConversationMemberDTO

nonisolated struct ConversationMemberDTO: Decodable, Sendable {
    let id: String
    let userId: String?
    let role: String?
    let isMuted: Bool?
    let lastReadAt: String?
    let userSummary: UserAuthorSummaryDTO?
    let username: String?
    let fullName: String?
    let isVerified: Bool?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, userId, role, isMuted, lastReadAt
        case userSummary = "user"
        case username, fullName, isVerified, avatarUrl
    }

    var resolvedUserId: String {
        userSummary?.id ?? userId ?? id
    }

    var resolvedUsername: String {
        userSummary?.username ?? username ?? ""
    }

    var resolvedFullName: String {
        userSummary?.fullName ?? fullName ?? ""
    }

    var resolvedAvatarUrl: String? {
        userSummary?.avatarUrl ?? avatarUrl
    }

    var resolvedIsVerified: Bool {
        userSummary?.isVerified ?? isVerified ?? false
    }

    var userEntity: User {
        User(
            id: resolvedUserId,
            username: resolvedUsername,
            fullName: resolvedFullName,
            email: nil,
            phone: nil,
            avatarURL: resolvedAvatarUrl.flatMap { URL(string: $0) },
            bio: nil,
            website: nil,
            isVerified: resolvedIsVerified,
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

    var user: User {
        userEntity
    }
}

// MARK: - MessageReactionDTO

nonisolated struct MessageReactionDTO: Decodable, Sendable, Identifiable {
    let id: String
    let messageId: String
    let userId: String
    let emoji: String
}

// MARK: - MessageDTO

/// API response model for Message. Matches BE response format.
nonisolated struct MessageDTO: Decodable, Sendable {
    let id: String
    let conversationId: String
    let senderId: String
    let contentType: String     // "TEXT" | "IMAGE" | "VIDEO" | "AUDIO" | "POST_SHARE" | "STORY_SHARE" | "REEL_SHARE" | "VOICE" | "SYSTEM" (uppercase)
    let textContent: String?
    let mediaUrl: String?
    let mediaThumbnail: String?
    let mediaDuration: Double?
    let referenceId: String?    // Post/Story/Reel ID when sharing content
    let replyToId: String?
    let status: String          // "SENT" | "DELIVERED" | "READ" (uppercase)
    let isEphemeral: Bool?
    let isEdited: Bool?
    let isUnsent: Bool?
    let createdAt: String
    let sender: MessageSenderDTO?        // Present in message detail, absent in conversation list
    let reactions: [MessageReactionDTO]?
    let lastReadAt: String?
    let isMuted: Bool?
    let unreadCount: Int?
}

// MARK: - MessageSenderDTO

/// Lightweight user object returned in message contexts.
/// BE returns: id, username, fullName, avatarUrl, isVerified, isFollowing
nonisolated struct MessageSenderDTO: Decodable, Sendable {
    let id: String
    let username: String?
    let fullName: String?
    let avatarUrl: String?
    let isVerified: Bool?
    let isFollowing: Bool?
}

// MARK: - ConversationWrapperDTO

/// Wrapper for single conversation response: `{ "conversation": {...} }`.
nonisolated struct ConversationWrapperDTO: Decodable, Sendable {
    let conversation: ConversationDTO
}

// MARK: - MessageWrapperDTO

/// Wrapper for single message response: `{ "message": {...} }`.
nonisolated struct MessageWrapperDTO: Decodable, Sendable {
    let message: MessageDTO
}

// MARK: - PaginatedConversationsDTO

nonisolated struct PaginatedConversationsDTO: Decodable, Sendable {
    let items: [ConversationDTO]
    let page: Int?
    let perPage: Int?
    let total: Int?
    let hasMore: Bool?
    let nextCursor: String?
}

// MARK: - PaginatedMessagesDTO

nonisolated struct PaginatedMessagesDTO: Decodable, Sendable {
    let items: [MessageDTO]
    let page: Int?
    let perPage: Int?
    let total: Int?
    let hasMore: Bool?
    let nextCursor: String?
}

// MARK: - GroupDetailsDTO

nonisolated struct GroupDetailsDTO: Decodable, Sendable {
    let name: String?
    let avatarUrl: String?
    let members: [GroupMemberDTO]
    let adminIds: [String]
    let sharedMedia: [SharedMediaDTO]
    let muteMessages: Bool
    let muteCalls: Bool
}

nonisolated struct GroupMemberDTO: Decodable, Sendable {
    let id: String
    let username: String
    let fullName: String?
    let avatarUrl: String?
    let isCurrentUser: Bool
}

nonisolated struct SharedMediaDTO: Decodable, Sendable {
    let id: String
    let type: String
    let thumbnailUrl: String?
    let mediaUrl: String
    let isVideo: Bool
}
