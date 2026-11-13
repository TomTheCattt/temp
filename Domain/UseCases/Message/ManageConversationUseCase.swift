//
//  ManageConversationUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - ManageConversationUseCase

protocol ManageConversationUseCaseProtocol: Sendable {
    func markAsRead(conversationId: String) async throws
    func markAsUnread(conversationId: String) async throws
    func deleteConversation(id: String) async throws
    func muteConversation(id: String, mute: Bool) async throws
    func createConversation(participantIds: [String], groupName: String?, groupAvatar: String?) async throws -> Conversation
}

final class ManageConversationUseCase: ManageConversationUseCaseProtocol, Sendable {

    private let messageRepository: MessageRepositoryProtocol

    init(messageRepository: MessageRepositoryProtocol) {
        self.messageRepository = messageRepository
    }

    func markAsRead(conversationId: String) async throws {
        try await messageRepository.markAsRead(conversationId: conversationId)
    }

    func markAsUnread(conversationId: String) async throws {
        try await messageRepository.markAsUnread(conversationId: conversationId)
    }

    func deleteConversation(id: String) async throws {
        try await messageRepository.deleteConversation(id: id)
    }

    func muteConversation(id: String, mute: Bool) async throws {
        try await messageRepository.muteConversation(id: id, mute: mute)
    }

    func createConversation(participantIds: [String], groupName: String? = nil, groupAvatar: String? = nil) async throws -> Conversation {
        try await messageRepository.createConversation(participantIds: participantIds, groupName: groupName, groupAvatar: groupAvatar)
    }
}
