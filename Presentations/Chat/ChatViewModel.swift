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

    var messages: [Message] = []
    var isLoading = false
    var isLoadingMore = false
    var isSending = false
    var errorMessage: String?

    var currentPage = 1
    var hasMorePages = false

    var recipient: User?
    var replyingToMessage: Message?
    var isPartnerTyping = false
    var isPartnerBlocked = false

    let conversationId: String
    var currentUserId: String {
        let storeId = SessionStore.shared.currentUserId
        if !storeId.isEmpty { return storeId }
        return injectedCurrentUserId
    }

    var restoreDraft: ((String) -> Void)?

    private let injectedCurrentUserId: String

    // MARK: - Dependencies

    private let fetchMessagesUseCase: FetchMessagesUseCaseProtocol
    private let sendMessageUseCase: SendMessageUseCaseProtocol
    private let messageRepository: MessageRepositoryProtocol

    // MARK: - Init

    init(
        conversationId: String,
        currentUserId: String,
        recipient: User? = nil,
        fetchMessagesUseCase: FetchMessagesUseCaseProtocol,
        sendMessageUseCase: SendMessageUseCaseProtocol,
        messageRepository: MessageRepositoryProtocol
    ) {
        self.conversationId = conversationId
        self.injectedCurrentUserId = currentUserId
        self.recipient = recipient
        self.fetchMessagesUseCase = fetchMessagesUseCase
        self.sendMessageUseCase = sendMessageUseCase
        self.messageRepository = messageRepository
    }

    // MARK: - Lifecycle

    func onAppear() {
        // TODO: Implement onAppear listener setup from scratch
    }

    func onDisappear() {
        // TODO: Implement onDisappear cleanup from scratch
    }

    // MARK: - Actions

    func loadMessages() async {
        // TODO: Implement loadMessages logic from scratch
    }

    func loadMoreMessages() async {
        // TODO: Implement loadMoreMessages logic from scratch
    }

    func sendTextMessage(_ text: String) async {
        _ = text
        // TODO: Implement sendTextMessage logic from scratch
    }

    func retryMessage(id: String) async {
        _ = id
        // TODO: Implement retryMessage logic from scratch
    }

    func addReaction(to messageId: String, emoji: String) {
        _ = messageId
        _ = emoji
        // TODO: Implement addReaction logic from scratch
    }

    func deleteMessage(id: String) {
        _ = id
        // TODO: Implement deleteMessage logic from scratch
    }

    func sendImageMessage(url: URL) async {
        _ = url
        // TODO: Implement sendImageMessage logic from scratch
    }

    func sendVideoMessage(url: URL, thumbnailURL: URL?) async {
        _ = url
        _ = thumbnailURL
        // TODO: Implement sendVideoMessage logic from scratch
    }

    func sendAudioMessage(url: URL, duration: TimeInterval) async {
        _ = url
        _ = duration
        // TODO: Implement sendAudioMessage logic from scratch
    }

    func sendLikeReaction() async {
        // TODO: Implement sendLikeReaction logic from scratch
    }

    func unblockPartner() {
        // TODO: Implement unblockPartner logic from scratch
    }

    func markAsRead() {
        // TODO: Implement markAsRead logic from scratch
    }
}
