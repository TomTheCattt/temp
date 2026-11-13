//
//  FetchConversationsUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - FetchConversationsUseCase

protocol FetchConversationsUseCaseProtocol: Sendable {
    func execute(page: Int, perPage: Int) async throws -> [Conversation]
}

final class FetchConversationsUseCase: FetchConversationsUseCaseProtocol, Sendable {

    private let messageRepository: MessageRepositoryProtocol

    init(messageRepository: MessageRepositoryProtocol) {
        self.messageRepository = messageRepository
    }

    func execute(page: Int = 1, perPage: Int = 20) async throws -> [Conversation] {
        try await messageRepository.fetchConversations(page: page, perPage: perPage)
    }
}
