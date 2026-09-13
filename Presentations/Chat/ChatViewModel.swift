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
    private(set) var isLoadingMore = false
    private(set) var isSending = false
    private(set) var errorMessage: String?

    private(set) var currentPage = 1
    private(set) var hasMorePages = true

    let conversationId: String

    /// Resolved current user id. Falls back to the shared session store when the
    /// injected value is empty so bubbles don't all render as incoming.
    var currentUserId: String {
        injectedCurrentUserId.isEmpty ? SessionStore.shared.currentUserId : injectedCurrentUserId
    }

    private let injectedCurrentUserId: String

    /// Page size used for every fetch. Keeps `hasMorePages` math consistent.
    private let perPage = DS.Layout.messagesPageSize

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
        self.injectedCurrentUserId = currentUserId
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
                FetchMessagesInput(conversationId: conversationId, page: 1, perPage: perPage)
            )
            messages = result.sorted { $0.createdAt > $1.createdAt }
            hasMorePages = result.count >= perPage

            // Mark as read
            try? await messageRepository.markAsRead(conversationId: conversationId)
        } catch {
            errorMessage = error.userMessage
        }

        isLoading = false
    }

    func loadMoreMessages() async {
        // Guard against concurrent loads and against re-triggering when exhausted.
        guard !isLoading, !isLoadingMore, hasMorePages else { return }
        isLoadingMore = true

        let nextPage = currentPage + 1
        do {
            let result = try await fetchMessagesUseCase.execute(
                FetchMessagesInput(conversationId: conversationId, page: nextPage, perPage: perPage)
            )
            currentPage = nextPage
            // Fewer than a full page means there's no more history.
            hasMorePages = result.count >= perPage
            mergeOlderMessages(result)
        } catch {
            // Don't retry silently in a loop: stop further auto-triggers and
            // surface the error since we already have messages on screen.
            hasMorePages = false
            ToastManager.shared.error(error.userMessage)
        }

        isLoadingMore = false
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
            simulateReadReceipt(for: message.id)
        } catch {
            ToastManager.shared.error(error.userMessage)
            // Restore the typed text so the user doesn't lose it on failure.
            restoreDraft?(text)
        }

        isSending = false
    }

    func sendImageMessage(url: URL) async {
        guard !isSending else { return }
        isSending = true

        do {
            let message = try await sendMessageUseCase.execute(
                SendMessageInput(conversationId: conversationId, content: .image(url))
            )
            messages.insert(message, at: 0)
            simulateReadReceipt(for: message.id)
        } catch {
            ToastManager.shared.error(error.userMessage)
        }

        isSending = false
    }

    func sendLikeReaction() async {
        guard !isSending else { return }
        isSending = true

        do {
            let message = try await sendMessageUseCase.execute(
                SendMessageInput(conversationId: conversationId, content: .like)
            )
            messages.insert(message, at: 0)
            simulateReadReceipt(for: message.id)
        } catch {
            ToastManager.shared.error(error.userMessage)
        }

        isSending = false
    }

    // MARK: - Draft restoration

    /// Set by the view to restore unsent text into the input field when a send fails.
    var restoreDraft: ((String) -> Void)?

    // MARK: - Private helpers

    /// Merge an older page into `messages`, keeping existing entries and appending
    /// only ids we haven't seen yet, then re-sort newest-first.
    private func mergeOlderMessages(_ older: [Message]) {
        guard !older.isEmpty else { return }
        var existingIds = Set(messages.map(\.id))
        var appended = false
        for message in older where !existingIds.contains(message.id) {
            messages.append(message)
            existingIds.insert(message.id)
            appended = true
        }
        if appended {
            messages.sort { $0.createdAt > $1.createdAt }
        }
    }

    /// Mock-friendly read-receipt simulation: after a short delay, flip a just-sent
    /// message from `.sent` to `.read` so the "Đã xem" receipt appears. Harmless in
    /// live mode — it only upgrades a local status and never mutates the backend.
    private func simulateReadReceipt(for messageId: String) {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(DS.Duration.chatReadReceipt * 1_000_000_000))
            guard let self else { return }
            guard let index = self.messages.firstIndex(where: { $0.id == messageId }) else { return }
            let current = self.messages[index]
            guard current.status != .read, current.status != .failed else { return }
            self.messages[index] = Message(
                id: current.id,
                conversationId: current.conversationId,
                sender: current.sender,
                content: current.content,
                status: .read,
                replyToId: current.replyToId,
                createdAt: current.createdAt
            )
        }
    }
}
