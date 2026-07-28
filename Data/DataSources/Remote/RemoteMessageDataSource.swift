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

    func fetchConversations(page: Int, perPage: Int) async throws -> [Conversation] {
        let response: PaginatedResponseDTO<ConversationDTO> = try await networkService.request(
            ConversationEndpoint.list(page: page, perPage: perPage)
        )
        return MessageMapper.toConversationList(response.items)
    }

    func fetchMessages(conversationId: String, page: Int, perPage: Int) async throws -> [Message] {
        let response: PaginatedResponseDTO<MessageDTO> = try await networkService.request(
            ConversationEndpoint.messages(conversationId: conversationId, page: page, perPage: perPage)
        )
        return MessageMapper.toMessageList(response.items)
    }

    func sendMessage(conversationId: String, content: MessageContent) async throws -> Message {
        let contentType = MessageMapper.contentTypeString(content)
        let contentValue = MessageMapper.contentValue(content)

        let dto: MessageDTO = try await networkService.request(
            ConversationEndpoint.send(conversationId: conversationId, contentType: contentType, content: contentValue)
        )
        return MessageMapper.toMessage(dto)
    }

    func createConversation(participantIds: [String]) async throws -> Conversation {
        let dto: ConversationDTO = try await networkService.request(
            ConversationEndpoint.create(participantIds: participantIds)
        )
        return MessageMapper.toConversation(dto)
    }

    func markAsRead(conversationId: String) async throws {
        try await networkService.requestVoid(ConversationEndpoint.markRead(conversationId: conversationId))
    }

    func deleteMessage(id: String) async throws {
        try await networkService.requestVoid(ConversationEndpoint.deleteMessage(messageId: id))
    }

    func muteConversation(id: String, mute: Bool) async throws {
        try await networkService.requestVoid(ConversationEndpoint.mute(conversationId: id, mute: mute))
    }
}
