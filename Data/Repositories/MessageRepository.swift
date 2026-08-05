//
//  MessageRepository.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - MessageRepository

final class MessageRepository: MessageRepositoryProtocol, @unchecked Sendable {

    private let remoteDataSource: RemoteMessageDataSource

    init(remoteDataSource: RemoteMessageDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchConversations(page: Int, perPage: Int) async throws -> [Conversation] {
        let currentUserId = SessionStore.shared.currentUserId
        return try await remoteDataSource.fetchConversations(page: page, perPage: perPage, currentUserId: currentUserId)
    }

    func fetchMessages(conversationId: String, page: Int, perPage: Int) async throws -> [Message] {
        try await remoteDataSource.fetchMessages(conversationId: conversationId, page: page, perPage: perPage)
    }

    func sendMessage(conversationId: String, content: MessageContent) async throws -> Message {
        switch content {
        case .text(let text):
            return try await remoteDataSource.sendTextMessage(conversationId: conversationId, text: text, replyToId: nil)
        case .image(let url):
            return try await remoteDataSource.sendMediaMessage(conversationId: conversationId, contentType: "IMAGE", mediaUrl: url.absoluteString, mediaThumbnail: nil, mediaDuration: nil)
        case .video(let url, let thumbnailURL):
            return try await remoteDataSource.sendMediaMessage(conversationId: conversationId, contentType: "VIDEO", mediaUrl: url.absoluteString, mediaThumbnail: thumbnailURL?.absoluteString, mediaDuration: nil)
        case .audio(let url, let duration):
            return try await remoteDataSource.sendMediaMessage(conversationId: conversationId, contentType: "AUDIO", mediaUrl: url.absoluteString, mediaThumbnail: nil, mediaDuration: duration)
        case .post(let postId):
            return try await remoteDataSource.sendMediaMessage(conversationId: conversationId, contentType: "POST", mediaUrl: postId, mediaThumbnail: nil, mediaDuration: nil)
        case .story(let storyId):
            return try await remoteDataSource.sendMediaMessage(conversationId: conversationId, contentType: "STORY", mediaUrl: storyId, mediaThumbnail: nil, mediaDuration: nil)
        case .reel(let reelId):
            return try await remoteDataSource.sendMediaMessage(conversationId: conversationId, contentType: "REEL", mediaUrl: reelId, mediaThumbnail: nil, mediaDuration: nil)
        case .like:
            return try await remoteDataSource.sendMediaMessage(conversationId: conversationId, contentType: "LIKE", mediaUrl: "", mediaThumbnail: nil, mediaDuration: nil)
        }
    }

    func createConversation(participantIds: [String]) async throws -> Conversation {
        try await remoteDataSource.createConversation(participantIds: participantIds, groupName: nil)
    }

    func markAsRead(conversationId: String) async throws {
        try await remoteDataSource.markRead(conversationId: conversationId)
    }

    func deleteMessage(id: String) async throws {
        try await remoteDataSource.deleteMessage(messageId: id)
    }

    func muteConversation(id: String, mute: Bool) async throws {
        try await remoteDataSource.muteConversation(conversationId: id, mute: mute)
    }
}
