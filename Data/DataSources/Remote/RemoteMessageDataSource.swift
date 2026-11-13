//
//  RemoteMessageDataSource.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - RemoteMessageDataSource

final class RemoteMessageDataSource: @unchecked Sendable {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    // MARK: - Conversations

    func fetchConversations(page: Int, perPage: Int, currentUserId: String) async throws -> [Conversation] {
        let response: PaginatedConversationsDTO = try await networkService.requestEnvelope(
            ConversationEndpoint.list(page: page, perPage: perPage)
        )
        return MessageMapper.toConversationList(response.items, currentUserId: currentUserId)
    }

    func createConversation(participantIds: [String], groupName: String?, groupAvatar: String?) async throws -> Conversation {
        let wrapper: ConversationWrapperDTO = try await networkService.requestEnvelope(
            ConversationEndpoint.create(participantIds: participantIds, groupName: groupName, groupAvatar: groupAvatar)
        )
        return MessageMapper.toConversation(wrapper.conversation, currentUserId: "")
    }

    // MARK: - Messages

    func fetchMessages(conversationId: String, cursor: String?, perPage: Int) async throws -> (messages: [Message], nextCursor: String?, hasMore: Bool) {
        let response: PaginatedMessagesDTO = try await networkService.requestEnvelope(
            ConversationEndpoint.messages(conversationId: conversationId, cursor: cursor, perPage: perPage)
        )
        return (MessageMapper.toMessageList(response.items), response.nextCursor, response.hasMore ?? false)
    }

    func sendTextMessage(conversationId: String, text: String, replyToId: String?) async throws -> Message {
        let wrapper: MessageWrapperDTO = try await networkService.requestEnvelope(
            ConversationEndpoint.sendText(conversationId: conversationId, textContent: text, replyToId: replyToId)
        )
        return MessageMapper.toMessage(wrapper.message)
    }

    func sendMediaMessage(conversationId: String, contentType: String, mediaUrl: String, mediaThumbnail: String?, mediaDuration: Double?) async throws -> Message {
        let wrapper: MessageWrapperDTO = try await networkService.requestEnvelope(
            ConversationEndpoint.sendMedia(conversationId: conversationId, contentType: contentType, mediaUrl: mediaUrl, mediaThumbnail: mediaThumbnail, mediaDuration: mediaDuration)
        )
        return MessageMapper.toMessage(wrapper.message)
    }

    // MARK: - Actions

    func markRead(conversationId: String) async throws {
        try await networkService.requestVoid(ConversationEndpoint.markRead(conversationId: conversationId))
    }

    func muteConversation(conversationId: String, mute: Bool) async throws {
        try await networkService.requestVoid(ConversationEndpoint.mute(conversationId: conversationId, mute: mute))
    }

    func deleteMessage(messageId: String) async throws {
        try await networkService.requestVoid(ConversationEndpoint.deleteMessage(messageId: messageId))
    }

    // MARK: - Group Chat

    func createGroupConversation(participantIds: [String], name: String?) async throws -> Conversation {
        let wrapper: ConversationWrapperDTO = try await networkService.requestEnvelope(
            ConversationEndpoint.createGroup(participantIds: participantIds, groupName: name)
        )
        return MessageMapper.toConversation(wrapper.conversation, currentUserId: "")
    }

    func fetchGroupDetails(id: String) async throws -> GroupDetails {
        let dto: GroupDetailsDTO = try await networkService.requestEnvelope(
            ConversationEndpoint.fetchGroupDetails(conversationId: id)
        )
        return MessageMapper.toGroupDetails(dto)
    }

    func updateGroupMuteSettings(id: String, muteMessages: Bool, muteCalls: Bool) async throws {
        try await networkService.requestVoid(
            ConversationEndpoint.updateGroupMuteSettings(conversationId: id, muteMessages: muteMessages, muteCalls: muteCalls)
        )
    }

    func leaveGroupConversation(id: String) async throws {
        try await networkService.requestVoid(ConversationEndpoint.leaveGroup(conversationId: id))
    }

    func deleteGroupConversation(id: String) async throws {
        try await networkService.requestVoid(ConversationEndpoint.deleteGroup(conversationId: id))
    }
}
