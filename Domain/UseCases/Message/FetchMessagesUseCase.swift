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
    let cursor: String?
    let perPage: Int

    init(conversationId: String, cursor: String? = nil, perPage: Int = 30) {
        self.conversationId = conversationId
        self.cursor = cursor
        self.perPage = perPage
    }
}

// MARK: - FetchMessagesOutput

struct FetchMessagesOutput: Sendable {
    let messages: [Message]
    let nextCursor: String?
    let hasMore: Bool
}

// MARK: - FetchMessagesUseCase

protocol FetchMessagesUseCaseProtocol: Sendable {
    func execute(_ input: FetchMessagesInput) async throws -> FetchMessagesOutput
}

final class FetchMessagesUseCase: FetchMessagesUseCaseProtocol, Sendable {

    private let messageRepository: MessageRepositoryProtocol

    init(messageRepository: MessageRepositoryProtocol) {
        self.messageRepository = messageRepository
    }

    func execute(_ input: FetchMessagesInput) async throws -> FetchMessagesOutput {
        let result = try await messageRepository.fetchMessages(
            conversationId: input.conversationId,
            cursor: input.cursor,
            perPage: input.perPage
        )
        return FetchMessagesOutput(
            messages: result.messages,
            nextCursor: result.nextCursor,
            hasMore: result.hasMore
        )
    }
}
