//
//  MessageDTO.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - ConversationDTO

/// API response model for Conversation.
nonisolated struct ConversationDTO: Decodable, Sendable {
    let id: String
    let participants: [UserDTO]
    let lastMessage: MessageDTO?
    let unreadCount: Int
    let isGroup: Bool
    let groupName: String?
    let groupAvatarUrl: String?
    let updatedAt: String
    let isMuted: Bool
}

// MARK: - MessageDTO

/// API response model for Message.
nonisolated struct MessageDTO: Decodable, Sendable {
    let id: String
    let conversationId: String
    let sender: UserDTO
    let contentType: String // "text" | "image" | "video" | "audio" | "post" | "story" | "reel" | "like"
    let content: String     // text content or URL/ID depending on type
    let thumbnailUrl: String?
    let duration: Double?   // for audio/video
    let status: String      // "sending" | "sent" | "delivered" | "read" | "failed"
    let replyToId: String?
    let createdAt: String
}
