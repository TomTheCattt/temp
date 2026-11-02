//
//  ChatSyncService.swift
//  Instagram
//
//  Created by Kiro on 28/10/26.
//

import Foundation
import Combine

// MARK: - ChatSyncService

/// Bridges WebSocket real-time chat events to local repository and ViewModels.
/// Handles: new messages, typing indicators, read receipts, message deletions.
@MainActor
final class ChatSyncService: ObservableObject {

    // MARK: - Dependencies

    private let webSocketMessageHandler: WebSocketMessageHandler
    private let messageRepository: MessageRepositoryProtocol

    // MARK: - State

    private var cancellables = Set<AnyCancellable>()
    private var activeConversationId: String?

    // MARK: - Typing Indicator State

    /// Tracks typing users per conversation: [conversationId: Set<userId>]
    private var typingUsers: [String: Set<String>] = [:]

    /// Debounce tasks for typing indicators (Swift 6 Sendable-compatible)
    private var typingTimers: [String: Task<Void, Never>] = [:]

    // MARK: - Init

    init(
        webSocketMessageHandler: WebSocketMessageHandler,
        messageRepository: MessageRepositoryProtocol
    ) {
        self.webSocketMessageHandler = webSocketMessageHandler
        self.messageRepository = messageRepository
        subscribeToWebSocketEvents()
    }

    // MARK: - Public API

    /// Call when entering a chat conversation to activate real-time sync for that conversation.
    func activateConversation(_ conversationId: String) {
        activeConversationId = conversationId
        // Subscribe to WebSocket channel for this conversation
        Task {
            try? await webSocketMessageHandler.send(.subscribe(channel: "conversation_\(conversationId)"))
        }
    }

    /// Call when leaving a chat conversation to deactivate real-time sync.
    func deactivateConversation() {
        if let conversationId = activeConversationId {
            Task {
                try? await webSocketMessageHandler.send(.unsubscribe(channel: "conversation_\(conversationId)"))
            }
            // Clear typing state for this conversation
            typingUsers[conversationId] = nil
            typingTimers[conversationId]?.cancel()
            typingTimers[conversationId] = nil
        }
        activeConversationId = nil
    }

    /// Returns current typing users for a conversation.
    func typingUsers(in conversationId: String) -> Set<String> {
        typingUsers[conversationId] ?? []
    }

    /// Checks if a specific user is typing in a conversation.
    func isUserTyping(_ userId: String, in conversationId: String) -> Bool {
        typingUsers[conversationId]?.contains(userId) ?? false
    }

    /// Send typing indicator start
    func startTyping() {
        guard let conversationId = activeConversationId else { return }
        Task {
            try? await webSocketMessageHandler.send(.startTyping(conversationId: conversationId))
        }
    }

    /// Send typing indicator stop
    func stopTyping() {
        guard let conversationId = activeConversationId else { return }
        Task {
            try? await webSocketMessageHandler.send(.stopTyping(conversationId: conversationId))
        }
    }

    // MARK: - WebSocket Subscription

    private func subscribeToWebSocketEvents() {
        // Subscribe to chat-specific messages
        webSocketMessageHandler.chatMessages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleChatMessage(message)
            }
            .store(in: &cancellables)
    }

    // MARK: - Message Handling

    private func handleChatMessage(_ message: WebSocketIncomingMessage) {
        switch message {
        case .newMessage(let message):
            handleNewMessage(message)

        case .typing(let conversationId, let userId):
            handleTypingStart(conversationId: conversationId, userId: userId)

        case .stopTyping(let conversationId, let userId):
            handleTypingStop(conversationId: conversationId, userId: userId)

        case .messageRead(let conversationId, let userId):
            handleMessageRead(conversationId: conversationId, userId: userId)

        case .messageDeleted(let conversationId, let messageId):
            handleMessageDeleted(conversationId: conversationId, messageId: messageId)

        default:
            break
        }
    }

    private func handleNewMessage(_ message: Message) {
        // Only process if we're in the active conversation
        guard message.conversationId == activeConversationId else {
            // For background conversations, we could update unread count in repository
            return
        }
        // The ViewModel will handle deduplication via its own subscription
    }

    private func handleTypingStart(conversationId: String, userId: String) {
        // Don't show typing indicator for current user
        guard userId != SessionStore.shared.currentUserId else { return }

        var users = typingUsers[conversationId] ?? []
        users.insert(userId)
        typingUsers[conversationId] = users

        // Auto-clear typing after 5 seconds if stop not received
        // Use Task-based timer instead of Timer for Swift 6 Sendable compatibility
        typingTimers[conversationId]?.cancel()

        let task = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(5))
            // Check if task was cancelled (user stopped typing)
            guard !Task.isCancelled else { return }
            self?.handleTypingStop(conversationId: conversationId, userId: userId)
        }
        typingTimers[conversationId] = task
    }

    private func handleTypingStop(conversationId: String, userId: String) {
        typingUsers[conversationId]?.remove(userId)
        if typingUsers[conversationId]?.isEmpty == true {
            typingUsers[conversationId] = nil
        }
        typingTimers[conversationId]?.cancel()
        typingTimers[conversationId] = nil
    }

    private func handleMessageRead(conversationId: String, userId: String) {
        // Update local read status
        NotificationCenter.default.post(
            name: .didUpdateMessageReadStatus,
            object: nil,
            userInfo: ["conversationId": conversationId, "userId": userId]
        )
    }

    private func handleMessageDeleted(conversationId: String, messageId: String) {
        NotificationCenter.default.post(
            name: .didDeleteMessage,
            object: nil,
            userInfo: ["conversationId": conversationId, "messageId": messageId]
        )
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let didUpdateMessageReadStatus = Notification.Name("didUpdateMessageReadStatus")
    static let didDeleteMessage = Notification.Name("didDeleteMessage")
}