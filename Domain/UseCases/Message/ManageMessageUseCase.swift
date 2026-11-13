//
//  ManageMessageUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - ManageMessageUseCase

protocol ManageMessageUseCaseProtocol: Sendable {
    func deleteMessage(id: String) async throws
    func addReaction(messageId: String, emoji: String) async throws
    func markAsRead(conversationId: String) async throws
}

final class ManageMessageUseCase: ManageMessageUseCaseProtocol, Sendable {

    private let messageRepository: MessageRepositoryProtocol

    init(messageRepository: MessageRepositoryProtocol) {
        self.messageRepository = messageRepository
    }

    func deleteMessage(id: String) async throws {
        try await messageRepository.deleteMessage(id: id)
    }

    func addReaction(messageId: String, emoji: String) async throws {
        try await messageRepository.addReaction(messageId: messageId, emoji: emoji)
    }

    func markAsRead(conversationId: String) async throws {
        try await messageRepository.markAsRead(conversationId: conversationId)
    }
}
