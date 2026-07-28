//
//  SendMessageUseCase.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - SendMessageInput

struct SendMessageInput: Sendable {
    let conversationId: String
    let content: MessageContent
}

// MARK: - SendMessageUseCase

protocol SendMessageUseCaseProtocol: Sendable {
    func execute(_ input: SendMessageInput) async throws -> Message
}

final class SendMessageUseCase: SendMessageUseCaseProtocol, Sendable {

    private let messageRepository: MessageRepositoryProtocol

    init(messageRepository: MessageRepositoryProtocol) {
        self.messageRepository = messageRepository
    }

    func execute(_ input: SendMessageInput) async throws -> Message {
        // Validate text messages are not empty
        if case .text(let text) = input.content {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw SendMessageError.emptyMessage
            }
        }

        return try await messageRepository.sendMessage(
            conversationId: input.conversationId,
            content: input.content
        )
    }
}

// MARK: - SendMessageError

private enum SendMessageError: LocalizedError {
    case emptyMessage

    var errorDescription: String? {
        switch self {
        case .emptyMessage: return "Message cannot be empty."
        }
    }
}
