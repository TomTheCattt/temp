//
//  FetchUnreadChatCountUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - FetchUnreadChatCountUseCase

protocol FetchUnreadChatCountUseCaseProtocol: Sendable {
    func execute() async throws -> Int
}

final class FetchUnreadChatCountUseCase: FetchUnreadChatCountUseCaseProtocol, Sendable {

    private let messageRepository: MessageRepositoryProtocol

    init(messageRepository: MessageRepositoryProtocol) {
        self.messageRepository = messageRepository
    }

    func execute() async throws -> Int {
        try await messageRepository.getUnreadConversationsCount()
    }
}
