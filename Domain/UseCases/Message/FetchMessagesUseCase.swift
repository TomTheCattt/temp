//
//  FetchMessagesUseCase.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - FetchMessagesInput

struct FetchMessagesInput: Sendable {
    let conversationId: String
    let page: Int
    let perPage: Int

    init(conversationId: String, page: Int = 1, perPage: Int = 30) {
        self.conversationId = conversationId
        self.page = page
        self.perPage = perPage
    }
}

// MARK: - FetchMessagesUseCase

protocol FetchMessagesUseCaseProtocol: Sendable {
    func execute(_ input: FetchMessagesInput) async throws -> [Message]
}

final class FetchMessagesUseCase: FetchMessagesUseCaseProtocol, Sendable {

    private let messageRepository: MessageRepositoryProtocol

    init(messageRepository: MessageRepositoryProtocol) {
        self.messageRepository = messageRepository
    }

    func execute(_ input: FetchMessagesInput) async throws -> [Message] {
        try await messageRepository.fetchMessages(
            conversationId: input.conversationId,
            page: input.page,
            perPage: input.perPage
        )
    }
}
