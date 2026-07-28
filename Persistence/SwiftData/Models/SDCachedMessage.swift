//
//  SDCachedMessage.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation
import SwiftData

// MARK: - SDCachedConversation

/// SwiftData model for caching Conversations offline.
@Model
final class SDCachedConversation {
    @Attribute(.unique) var id: String
    var participantIds: [String]
    var participantUsernames: [String]
    var participantAvatarURLs: [String]
    var lastMessageText: String?
    var lastMessageContentType: String?
    var lastMessageSenderId: String?
    var lastMessageCreatedAt: Date?
    var unreadCount: Int
    var isGroup: Bool
    var groupName: String?
    var updatedAt: Date
    var isMuted: Bool
    var cachedAt: Date

    init(
        id: String,
        participantIds: [String] = [],
        participantUsernames: [String] = [],
        participantAvatarURLs: [String] = [],
        lastMessageText: String? = nil,
        lastMessageContentType: String? = nil,
        lastMessageSenderId: String? = nil,
        lastMessageCreatedAt: Date? = nil,
        unreadCount: Int = 0,
        isGroup: Bool = false,
        groupName: String? = nil,
        updatedAt: Date = .now,
        isMuted: Bool = false,
        cachedAt: Date = .now
    ) {
        self.id = id
        self.participantIds = participantIds
        self.participantUsernames = participantUsernames
        self.participantAvatarURLs = participantAvatarURLs
        self.lastMessageText = lastMessageText
        self.lastMessageContentType = lastMessageContentType
        self.lastMessageSenderId = lastMessageSenderId
        self.lastMessageCreatedAt = lastMessageCreatedAt
        self.unreadCount = unreadCount
        self.isGroup = isGroup
        self.groupName = groupName
        self.updatedAt = updatedAt
        self.isMuted = isMuted
        self.cachedAt = cachedAt
    }
}

// MARK: - SDCachedMessage

/// SwiftData model for caching Messages offline.
@Model
final class SDCachedMessage {
    @Attribute(.unique) var id: String
    var conversationId: String
    var senderId: String
    var senderUsername: String
    var senderAvatarURL: String?
    var contentType: String // "text" | "image" | "video" | "audio" | "post" | "story" | "reel" | "like"
    var contentValue: String // text or URL/ID
    var thumbnailURL: String?
    var duration: Double?
    var status: String // "sending" | "sent" | "delivered" | "read" | "failed"
    var replyToId: String?
    var createdAt: Date
    var cachedAt: Date

    init(
        id: String,
        conversationId: String,
        senderId: String,
        senderUsername: String,
        senderAvatarURL: String? = nil,
        contentType: String,
        contentValue: String,
        thumbnailURL: String? = nil,
        duration: Double? = nil,
        status: String = "sent",
        replyToId: String? = nil,
        createdAt: Date = .now,
        cachedAt: Date = .now
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderUsername = senderUsername
        self.senderAvatarURL = senderAvatarURL
        self.contentType = contentType
        self.contentValue = contentValue
        self.thumbnailURL = thumbnailURL
        self.duration = duration
        self.status = status
        self.replyToId = replyToId
        self.createdAt = createdAt
        self.cachedAt = cachedAt
    }
}

// MARK: - Entity Mapping

extension SDCachedMessage {

    convenience init(from message: Message) {
        self.init(
            id: message.id,
            conversationId: message.conversationId,
            senderId: message.sender.id,
            senderUsername: message.sender.username,
            senderAvatarURL: message.sender.avatarURL?.absoluteString,
            contentType: MessageMapper.contentTypeString(message.content),
            contentValue: MessageMapper.contentValue(message.content),
            status: message.status.rawValue,
            replyToId: message.replyToId,
            createdAt: message.createdAt,
            cachedAt: .now
        )
    }
}
