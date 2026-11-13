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
    private let sessionStore: SessionStoreProtocol

    init(remoteDataSource: RemoteMessageDataSource, sessionStore: SessionStoreProtocol) {
        self.remoteDataSource = remoteDataSource
        self.sessionStore = sessionStore
    }

    func fetchConversations(page: Int, perPage: Int) async throws -> [Conversation] {
        let currentUserId = await MainActor.run { sessionStore.currentUserId }
        return try await remoteDataSource.fetchConversations(page: page, perPage: perPage, currentUserId: currentUserId)
    }

    func fetchMessages(conversationId: String, cursor: String?, perPage: Int) async throws -> (messages: [Message], nextCursor: String?, hasMore: Bool) {
        try await remoteDataSource.fetchMessages(conversationId: conversationId, cursor: cursor, perPage: perPage)
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

    func createConversation(participantIds: [String], groupName: String? = nil, groupAvatar: String? = nil) async throws -> Conversation {
        try await remoteDataSource.createConversation(participantIds: participantIds, groupName: groupName, groupAvatar: groupAvatar)
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

    func markAsUnread(conversationId: String) async throws {
        // Not implemented in remote data source yet
    }

    func getUnreadConversationsCount() async throws -> Int {
        return 0
    }

    func deleteConversation(id: String) async throws {
        // Not implemented in remote data source yet
    }

    func addReaction(messageId: String, emoji: String) async throws {
        // Not implemented in remote data source yet
    }

    func fetchNotes() async throws -> [InstagramNote] {
        return []
    }

    func saveNote(text: String) async throws -> InstagramNote {
        throw NSError(domain: "MessageRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "saveNote not implemented"])
    }

    func detachMessageListener(for conversationId: String) async {
        // Not implemented in remote data source yet
    }

    func resetSession() async {
        // Not implemented in remote data source yet
    }

    func createGroupConversation(participantIds: [String], name: String?) async throws -> Conversation {
        try await remoteDataSource.createGroupConversation(participantIds: participantIds, name: name)
    }

    func fetchGroupDetails(id: String) async throws -> GroupDetails {
        try await remoteDataSource.fetchGroupDetails(id: id)
    }

    func updateGroupMuteSettings(id: String, muteMessages: Bool, muteCalls: Bool) async throws {
        try await remoteDataSource.updateGroupMuteSettings(id: id, muteMessages: muteMessages, muteCalls: muteCalls)
    }

    func leaveGroupConversation(id: String) async throws {
        try await remoteDataSource.leaveGroupConversation(id: id)
    }

    func deleteGroupConversation(id: String) async throws {
        try await remoteDataSource.deleteGroupConversation(id: id)
    }
}
