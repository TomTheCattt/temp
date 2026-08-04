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
    let messages: [MessageDTO]?     // Last message(s) included in list response
}

// MARK: - ConversationMemberDTO

nonisolated struct ConversationMemberDTO: Decodable, Sendable {
    let id: String
    let conversationId: String
    let userId: String
    let isMuted: Bool
    let lastReadAt: String?
    let joinedAt: String
    let user: UserDTO
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
    let sender: UserDTO?        // Present in message detail, absent in conversation list
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
    let page: Int
    let perPage: Int
    let total: Int
    let hasMore: Bool
}

// MARK: - PaginatedMessagesDTO

nonisolated struct PaginatedMessagesDTO: Decodable, Sendable {
    let items: [MessageDTO]
    let page: Int
    let perPage: Int
    let total: Int
    let hasMore: Bool
}
