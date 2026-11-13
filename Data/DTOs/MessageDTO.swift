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
    let createdAt: String
    let updatedAt: String
    let members: [ConversationMemberDTO]
    let lastMessage: MessageDTO?
    let lastReadAt: String?
    let isMuted: Bool
    let unreadCount: Int
}

// MARK: - ConversationMemberDTO

nonisolated struct ConversationMemberDTO: Decodable, Sendable {
    let id: String
    let username: String?
    let fullName: String?
    let isVerified: Bool?
    let avatarUrl: String?
    
    var user: User {
        return User(
            id: id,
            username: username ?? "",
            fullName: fullName ?? "",
            email: nil,
            phone: nil,
            avatarURL: URL(string: avatarUrl ?? ""),
            bio: nil,
            website: nil,
            isVerified: isVerified ?? false,
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
}

// MARK: - MessageDTO

/// API response model for Message. Matches BE response format.
nonisolated struct MessageDTO: Decodable, Sendable {
    let id: String
    let conversationId: String
    let senderId: String
    let contentType: String     // "TEXT" | "IMAGE" | "VIDEO" | "AUDIO" | "POST" | "STORY" | "REEL" | "LIKE" (uppercase)
    let textContent: String?
    let mediaUrl: String?
    let mediaThumbnail: String?
    let mediaDuration: Double?
    let referenceId: String?    // Post/Story/Reel ID when sharing content
    let replyToId: String?
    let status: String          // "SENT" | "DELIVERED" | "READ" (uppercase)
    let createdAt: String
    let sender: MessageSenderDTO?        // Present in message detail, absent in conversation list
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
