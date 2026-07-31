//
//  ChatViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - ChatViewModel

@MainActor
@Observable
final class ChatViewModel {

    // MARK: - State

    private(set) var messages: [Message] = []
    private(set) var isLoading = false
    private(set) var isSending = false
    private(set) var errorMessage: String?

    private var currentPage = 1
    private var hasMorePages = true

    let conversationId: String
    let currentUserId: String

    // MARK: - Dependencies

    private let fetchMessagesUseCase: FetchMessagesUseCaseProtocol
    private let sendMessageUseCase: SendMessageUseCaseProtocol
    private let messageRepository: MessageRepositoryProtocol

    // MARK: - Init

    init(
        conversationId: String,
        currentUserId: String,
        fetchMessagesUseCase: FetchMessagesUseCaseProtocol,
        sendMessageUseCase: SendMessageUseCaseProtocol,
        messageRepository: MessageRepositoryProtocol
    ) {
        self.conversationId = conversationId
        self.currentUserId = currentUserId
        self.fetchMessagesUseCase = fetchMessagesUseCase
        self.sendMessageUseCase = sendMessageUseCase
        self.messageRepository = messageRepository
    }

    // MARK: - Actions

    func loadMessages() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        currentPage = 1

        do {
            let result = try await fetchMessagesUseCase.execute(
                FetchMessagesInput(conversationId: conversationId, page: 1)
            )
            messages = result.sorted { $0.createdAt > $1.createdAt }
            hasMorePages = result.count >= 30

            // Mark as read
            try? await messageRepository.markAsRead(conversationId: conversationId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadMoreMessages() async {
        guard !isLoading, hasMorePages else { return }
        isLoading = true

        let nextPage = currentPage + 1
        do {
            let result = try await fetchMessagesUseCase.execute(
                FetchMessagesInput(conversationId: conversationId, page: nextPage)
            )
            messages.append(contentsOf: result)
            messages.sort { $0.createdAt > $1.createdAt }
            currentPage = nextPage
            hasMorePages = result.count >= 30
        } catch {
            // Silent fail
        }

        isLoading = false
    }

    func sendTextMessage(_ text: String) async {
        guard !isSending else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true

        do {
            let message = try await sendMessageUseCase.execute(
                SendMessageInput(conversationId: conversationId, content: .text(trimmed))
            )
            messages.insert(message, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }

        isSending = false
    }

    func sendImageMessage(url: URL) async {
        isSending = true

        do {
            let message = try await sendMessageUseCase.execute(
                SendMessageInput(conversationId: conversationId, content: .image(url))
            )
            messages.insert(message, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }

        isSending = false
    }

    func sendLikeReaction() async {
        do {
            let message = try await sendMessageUseCase.execute(
                SendMessageInput(conversationId: conversationId, content: .like)
            )
            messages.insert(message, at: 0)
        } catch {
            // Silent fail
        }
    }
}
