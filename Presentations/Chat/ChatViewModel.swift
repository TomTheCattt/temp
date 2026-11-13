//
//  ChatViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation
import Combine

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

    var currentCursor: String?
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
    private let manageMessageUseCase: ManageMessageUseCaseProtocol
    private let chatSyncService: ChatSyncService

    // MARK: - Private State

    private var cancellables = Set<AnyCancellable>()
    private var pendingMessages: Set<String> = [] // Track optimistic messages by temp ID
    private var loadMoreTask: Task<Void, Never>?

    // MARK: - Init

    init(
        conversationId: String,
        currentUserId: String,
        recipient: User? = nil,
        fetchMessagesUseCase: FetchMessagesUseCaseProtocol,
        sendMessageUseCase: SendMessageUseCaseProtocol,
        manageMessageUseCase: ManageMessageUseCaseProtocol,
        chatSyncService: ChatSyncService
    ) {
        self.conversationId = conversationId
        self.injectedCurrentUserId = currentUserId
        self.recipient = recipient
        self.fetchMessagesUseCase = fetchMessagesUseCase
        self.sendMessageUseCase = sendMessageUseCase
        self.manageMessageUseCase = manageMessageUseCase
        self.chatSyncService = chatSyncService

        // Set up offline message queue send handler
        OfflineMessageQueue.shared.sendHandler = { [weak self] queuedMessage in
            guard let self = self else { return }

            let input = SendMessageInput(
                conversationId: queuedMessage.conversationId,
                content: queuedMessage.content,
                replyToId: queuedMessage.replyToId,
                replyToSnippet: queuedMessage.replyToSnippet
            )
            _ = try await self.sendMessageUseCase.execute(input)
        }
    }

    // MARK: - Lifecycle

    func onAppear() {
        chatSyncService.activateConversation(conversationId)
        subscribeToRealTimeUpdates()
        loadMessages()
    }

    func onDisappear() {
        chatSyncService.deactivateConversation()
        cancellables.removeAll()
        loadMoreTask?.cancel()
    }

    // MARK: - Real-time Subscriptions

    private func subscribeToRealTimeUpdates() {
        // Observe typing indicator
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTypingIndicator()
            }
            .store(in: &cancellables)

        // Observe message read status
        NotificationCenter.default
            .publisher(for: .didUpdateMessageReadStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self,
                      let conversationId = notification.userInfo?["conversationId"] as? String,
                      conversationId == self.conversationId,
                      let userId = notification.userInfo?["userId"] as? String else { return }
                self.handleMessageRead(userId: userId)
            }
            .store(in: &cancellables)

        // Observe message deletion
        NotificationCenter.default
            .publisher(for: .didDeleteMessage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self,
                      let conversationId = notification.userInfo?["conversationId"] as? String,
                      conversationId == self.conversationId,
                      let messageId = notification.userInfo?["messageId"] as? String else { return }
                self.handleMessageDeleted(messageId: messageId)
            }
            .store(in: &cancellables)

        // Observe new messages from WebSocket (via ChatSyncService)
        // The ChatSyncService doesn't directly expose newMessage publisher,
        // but we can observe via NotificationCenter if needed
        NotificationCenter.default
            .publisher(for: .didUpdateMessage)
            .receive(on: DispatchQueue.main)
            .compactMap { $0.object as? Message }
            .filter { $0.conversationId == self.conversationId }
            .sink { [weak self] message in
                self?.handleIncomingMessage(message)
            }
            .store(in: &cancellables)
    }

    private func updateTypingIndicator() {
        let typing = chatSyncService.isUserTyping(recipient?.id ?? "", in: conversationId)
        if isPartnerTyping != typing {
            isPartnerTyping = typing
        }
    }

    // MARK: - Media Preloading

    private func preloadMedia(for messages: [Message]) {
        let urls = messages.compactMap { message -> [URL] in
            switch message.content {
            case .image(let url):
                return [url]
            case .video(let url, let thumbnailURL):
                var urls = [url]
                if let thumb = thumbnailURL { urls.append(thumb) }
                return urls
            case .audio(let url, _):
                return [url]
            default:
                return []
            }
        }.flatMap { $0 }
        
        guard !urls.isEmpty else { return }
        
        // Use ImagePrefetchService to preload images/videos
        ImagePrefetchService.shared.startPrefetching(urls: urls)
    }

    // MARK: - Actions

    func loadMessages() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        currentCursor = nil

        Task {
            do {
                let input = FetchMessagesInput(conversationId: conversationId, cursor: nil, perPage: 30)
                let output = try await fetchMessagesUseCase.execute(input)

                await MainActor.run {
                    // Deduplicate with any pending optimistic messages
                    self.messages = self.mergeMessages(existing: self.messages, new: output.messages)
                    self.currentCursor = output.nextCursor
                    self.hasMorePages = output.hasMore
                    self.isLoading = false
                }
                // Preload media for loaded messages
                preloadMedia(for: output.messages)
            } catch {
                await MainActor.run {
                    self.errorMessage = error.userMessage
                    self.isLoading = false
                }
            }
        }
    }

    func loadMoreMessages() {
        guard !isLoadingMore && hasMorePages, let cursor = currentCursor else { return }
        loadMoreTask?.cancel()

        loadMoreTask = Task {
            await MainActor.run { self.isLoadingMore = true }

            do {
                let input = FetchMessagesInput(conversationId: conversationId, cursor: cursor, perPage: 30)
                let output = try await fetchMessagesUseCase.execute(input)

                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    // Prepend older messages
                    self.messages = self.mergeMessages(existing: output.messages, new: self.messages)
                    self.currentCursor = output.nextCursor
                    self.hasMorePages = output.hasMore
                    self.isLoadingMore = false
                }
                // Preload media for loaded messages
                preloadMedia(for: output.messages)
            } catch {
                await MainActor.run {
                    self.isLoadingMore = false
                    // Don't overwrite errorMessage for pagination errors
                }
            }
        }
    }

    func sendTextMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        await MainActor.run { self.isSending = true }

        // Create optimistic message
        let tempId = UUID().uuidString
        let optimisticMessage = Message(
            id: tempId,
            conversationId: conversationId,
            sender: User(
                id: currentUserId,
                username: "me",
                fullName: "Me",
                email: nil,
                phone: nil,
                avatarURL: nil,
                bio: nil,
                website: nil,
                isVerified: false,
                isPrivate: false,
                followersCount: 0,
                followingCount: 0,
                postsCount: 0,
                createdAt: .now,
                isFollowing: false,
                isFollowedBy: false,
                isBlocked: false
            ),
            content: .text(trimmed),
            status: .sending,
            replyToId: replyingToMessage?.id,
            replyToSnippet: replyingToMessage?.content.textContent.map { String($0.prefix(50)) },
            reactions: [:],
            createdAt: Date()
        )

        await MainActor.run {
            pendingMessages.insert(tempId)
            messages.append(optimisticMessage)
            isSending = false
            replyingToMessage = nil
        }

        do {
            let input = SendMessageInput(
                conversationId: conversationId,
                content: .text(trimmed),
                replyToId: replyingToMessage?.id,
                replyToSnippet: replyingToMessage?.content.textContent.map { String($0.prefix(50)) }
            )
            let serverMessage = try await sendMessageUseCase.execute(input)

            await MainActor.run {
                // Replace optimistic message with server message
                if let index = messages.firstIndex(where: { $0.id == tempId }) {
                    messages[index] = serverMessage
                } else {
                    // If not found (e.g., already replaced by real-time), append if not duplicate
                    if !messages.contains(where: { $0.id == serverMessage.id }) {
                        messages.append(serverMessage)
                    }
                }
                pendingMessages.remove(tempId)
            }
        } catch {
            await MainActor.run {
                // Mark as failed, keep in list for retry
                if let index = messages.firstIndex(where: { $0.id == tempId }) {
                    messages[index] = Message(
                        id: messages[index].id,
                        conversationId: messages[index].conversationId,
                        sender: messages[index].sender,
                        content: messages[index].content,
                        status: .failed,
                        replyToId: messages[index].replyToId,
                        replyToSnippet: messages[index].replyToSnippet,
                        reactions: messages[index].reactions,
                        createdAt: messages[index].createdAt
                    )
                }
                errorMessage = error.userMessage
                isSending = false
            }
        }
    }

    func retryMessage(id: String) async {
        guard let message = messages.first(where: { $0.id == id }),
              message.status == .failed else { return }

        await MainActor.run {
            if let index = messages.firstIndex(where: { $0.id == id }) {
                messages[index] = Message(
                    id: message.id,
                    conversationId: message.conversationId,
                    sender: message.sender,
                    content: message.content,
                    status: .sending,
                    replyToId: message.replyToId,
                    replyToSnippet: message.replyToSnippet,
                    reactions: message.reactions,
                    createdAt: message.createdAt
                )
            }
        }

        // Retry based on content type
        switch message.content {
        case .text(let text):
            await sendTextMessage(text)
        case .image(let url):
            await sendImageMessage(url: url)
        case .video(let url, let thumb):
            await sendVideoMessage(url: url, thumbnailURL: thumb)
        case .audio(let url, let duration):
            await sendAudioMessage(url: url, duration: duration)
        case .post, .story, .reel, .like:
            // These need special handling - for now just show error
            await MainActor.run { errorMessage = "Retry not supported for this message type" }
        }
    }

    func addReaction(to messageId: String, emoji: String) {
        guard let message = messages.first(where: { $0.id == messageId }),
              !message.reactions.keys.contains(currentUserId) else { return }

        // Optimistic update
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            var updatedReactions = messages[index].reactions
            updatedReactions[currentUserId] = emoji
            messages[index] = Message(
                id: messages[index].id,
                conversationId: messages[index].conversationId,
                sender: messages[index].sender,
                content: messages[index].content,
                status: messages[index].status,
                replyToId: messages[index].replyToId,
                replyToSnippet: messages[index].replyToSnippet,
                reactions: updatedReactions,
                createdAt: messages[index].createdAt
            )
        }

        Task {
            do {
                try await manageMessageUseCase.addReaction(messageId: messageId, emoji: emoji)
            } catch {
                // Rollback on failure
                await MainActor.run {
                    if let index = messages.firstIndex(where: { $0.id == messageId }) {
                        var updatedReactions = messages[index].reactions
                        updatedReactions.removeValue(forKey: currentUserId)
                        messages[index] = Message(
                            id: messages[index].id,
                            conversationId: messages[index].conversationId,
                            sender: messages[index].sender,
                            content: messages[index].content,
                            status: messages[index].status,
                            replyToId: messages[index].replyToId,
                            replyToSnippet: messages[index].replyToSnippet,
                            reactions: updatedReactions,
                            createdAt: messages[index].createdAt
                        )
                    }
                }
            }
        }
    }

    func deleteMessage(id: String) {
        guard let message = messages.first(where: { $0.id == id }) else { return }

        // Optimistic delete
        messages.removeAll { $0.id == id }

        Task {
            do {
                try await manageMessageUseCase.deleteMessage(id: id)
            } catch {
                // Rollback - reinsert message
                await MainActor.run {
                    messages.append(message)
                    messages.sort { $0.createdAt < $1.createdAt }
                }
            }
        }
    }

    func sendImageMessage(url: URL) async {
        await MainActor.run { isSending = true }

        let tempId = UUID().uuidString
        let optimisticMessage = Message(
            id: tempId,
            conversationId: conversationId,
            sender: User(
                id: currentUserId,
                username: "me",
                fullName: "Me",
                email: nil,
                phone: nil,
                avatarURL: nil,
                bio: nil,
                website: nil,
                isVerified: false,
                isPrivate: false,
                followersCount: 0,
                followingCount: 0,
                postsCount: 0,
                createdAt: .now,
                isFollowing: false,
                isFollowedBy: false,
                isBlocked: false
            ),
            content: .image(url),
            status: .sending,
            replyToId: replyingToMessage?.id,
            replyToSnippet: replyingToMessage?.content.textContent.map { String($0.prefix(50)) },
            reactions: [:],
            createdAt: Date()
        )

        await MainActor.run {
            pendingMessages.insert(tempId)
            messages.append(optimisticMessage)
            isSending = false
            replyingToMessage = nil
        }

        do {
            let input = SendMessageInput(
                conversationId: conversationId,
                content: .image(url),
                replyToId: replyingToMessage?.id,
                replyToSnippet: replyingToMessage?.content.textContent.map { String($0.prefix(50)) }
            )
            let serverMessage = try await sendMessageUseCase.execute(input)

            await MainActor.run {
                if let index = messages.firstIndex(where: { $0.id == tempId }) {
                    messages[index] = serverMessage
                } else if !messages.contains(where: { $0.id == serverMessage.id }) {
                    messages.append(serverMessage)
                }
                pendingMessages.remove(tempId)
            }
        } catch {
            await MainActor.run {
                if let index = messages.firstIndex(where: { $0.id == tempId }) {
                    messages[index] = Message(
                        id: messages[index].id,
                        conversationId: messages[index].conversationId,
                        sender: messages[index].sender,
                        content: messages[index].content,
                        status: .failed,
                        replyToId: messages[index].replyToId,
                        replyToSnippet: messages[index].replyToSnippet,
                        reactions: messages[index].reactions,
                        createdAt: messages[index].createdAt
                    )
                }
                errorMessage = error.userMessage
                isSending = false

                // Enqueue failed message for offline retry
                if let index = messages.firstIndex(where: { $0.id == tempId }) {
                    let failedMessage = messages[index]
                    let sendActionData: SendActionData
                    switch failedMessage.content {
                    case .text(let text):
                        sendActionData = .text(text, replyToId: failedMessage.replyToId)
                    case .image(let url):
                        sendActionData = .image(url, replyToId: failedMessage.replyToId)
                    case .video(let url, let thumbnailURL):
                        sendActionData = .video(url, thumbnailURL: thumbnailURL, replyToId: failedMessage.replyToId)
                    case .audio(let url, let duration):
                        sendActionData = .audio(url, duration: duration, replyToId: failedMessage.replyToId)
                    case .like:
                        sendActionData = .like(failedMessage.replyToId)
                    default:
                        sendActionData = .text("", replyToId: failedMessage.replyToId)
                    }

                    let queuedMessage = QueuedMessage(
                        id: failedMessage.id,
                        conversationId: failedMessage.conversationId,
                        content: failedMessage.content,
                        replyToId: failedMessage.replyToId,
                        replyToSnippet: failedMessage.replyToSnippet,
                        createdAt: failedMessage.createdAt,
                        sendActionData: sendActionData
                    )
                    OfflineMessageQueue.shared.enqueue(queuedMessage)
                }
            }
        }
    }

    func sendVideoMessage(url: URL, thumbnailURL: URL?) async {
        await MainActor.run { isSending = true }

        let tempId = UUID().uuidString
        let optimisticMessage = Message(
            id: tempId,
            conversationId: conversationId,
            sender: User(
                id: currentUserId,
                username: "me",
                fullName: "Me",
                email: nil,
                phone: nil,
                avatarURL: nil,
                bio: nil,
                website: nil,
                isVerified: false,
                isPrivate: false,
                followersCount: 0,
                followingCount: 0,
                postsCount: 0,
                createdAt: .now,
                isFollowing: false,
                isFollowedBy: false,
                isBlocked: false
            ),
            content: .video(url, thumbnailURL: thumbnailURL),
            status: .sending,
            replyToId: replyingToMessage?.id,
            replyToSnippet: replyingToMessage?.content.textContent.map { String($0.prefix(50)) },
            reactions: [:],
            createdAt: Date()
        )

        await MainActor.run {
            pendingMessages.insert(tempId)
            messages.append(optimisticMessage)
            isSending = false
            replyingToMessage = nil
        }

        do {
            let input = SendMessageInput(
                conversationId: conversationId,
                content: .video(url, thumbnailURL: thumbnailURL),
                replyToId: replyingToMessage?.id,
                replyToSnippet: replyingToMessage?.content.textContent.map { String($0.prefix(50)) }
            )
            let serverMessage = try await sendMessageUseCase.execute(input)

            await MainActor.run {
                if let index = messages.firstIndex(where: { $0.id == tempId }) {
                    messages[index] = serverMessage
                } else if !messages.contains(where: { $0.id == serverMessage.id }) {
                    messages.append(serverMessage)
                }
                pendingMessages.remove(tempId)
            }
        } catch {
            await MainActor.run {
                if let index = messages.firstIndex(where: { $0.id == tempId }) {
                    messages[index] = Message(
                        id: messages[index].id,
                        conversationId: messages[index].conversationId,
                        sender: messages[index].sender,
                        content: messages[index].content,
                        status: .failed,
                        replyToId: messages[index].replyToId,
                        replyToSnippet: messages[index].replyToSnippet,
                        reactions: messages[index].reactions,
                        createdAt: messages[index].createdAt
                    )
                }
                errorMessage = error.userMessage
                isSending = false

                // Enqueue failed message for offline retry
                if let index = messages.firstIndex(where: { $0.id == tempId }) {
                    let failedMessage = messages[index]
                    let sendActionData: SendActionData
                    switch failedMessage.content {
                    case .text(let text):
                        sendActionData = .text(text, replyToId: failedMessage.replyToId)
                    case .image(let url):
                        sendActionData = .image(url, replyToId: failedMessage.replyToId)
                    case .video(let url, let thumbnailURL):
                        sendActionData = .video(url, thumbnailURL: thumbnailURL, replyToId: failedMessage.replyToId)
                    case .audio(let url, let duration):
                        sendActionData = .audio(url, duration: duration, replyToId: failedMessage.replyToId)
                    case .like:
                        sendActionData = .like(failedMessage.replyToId)
                    default:
                        sendActionData = .text("", replyToId: failedMessage.replyToId)
                    }

                    let queuedMessage = QueuedMessage(
                        id: failedMessage.id,
                        conversationId: failedMessage.conversationId,
                        content: failedMessage.content,
                        replyToId: failedMessage.replyToId,
                        replyToSnippet: failedMessage.replyToSnippet,
                        createdAt: failedMessage.createdAt,
                        sendActionData: sendActionData
                    )
                    OfflineMessageQueue.shared.enqueue(queuedMessage)
                }
            }
        }
    }

    func sendAudioMessage(url: URL, duration: TimeInterval) async {
        await MainActor.run { isSending = true }

        let tempId = UUID().uuidString
        let optimisticMessage = Message(
            id: tempId,
            conversationId: conversationId,
            sender: User(
                id: currentUserId,
                username: "me",
                fullName: "Me",
                email: nil,
                phone: nil,
                avatarURL: nil,
                bio: nil,
                website: nil,
                isVerified: false,
                isPrivate: false,
                followersCount: 0,
                followingCount: 0,
                postsCount: 0,
                createdAt: .now,
                isFollowing: false,
                isFollowedBy: false,
                isBlocked: false
            ),
            content: .audio(url, duration: duration),
            status: .sending,
            replyToId: replyingToMessage?.id,
            replyToSnippet: replyingToMessage?.content.textContent.map { String($0.prefix(50)) },
            reactions: [:],
            createdAt: Date()
        )

        await MainActor.run {
            pendingMessages.insert(tempId)
            messages.append(optimisticMessage)
            isSending = false
            replyingToMessage = nil
        }

        do {
            let input = SendMessageInput(
                conversationId: conversationId,
                content: .audio(url, duration: duration),
                replyToId: replyingToMessage?.id,
                replyToSnippet: replyingToMessage?.content.textContent.map { String($0.prefix(50)) }
            )
            let serverMessage = try await sendMessageUseCase.execute(input)

            await MainActor.run {
                if let index = messages.firstIndex(where: { $0.id == tempId }) {
                    messages[index] = serverMessage
                } else if !messages.contains(where: { $0.id == serverMessage.id }) {
                    messages.append(serverMessage)
                }
                pendingMessages.remove(tempId)
            }
        } catch {
            await MainActor.run {
                if let index = messages.firstIndex(where: { $0.id == tempId }) {
                    messages[index] = Message(
                        id: messages[index].id,
                        conversationId: messages[index].conversationId,
                        sender: messages[index].sender,
                        content: messages[index].content,
                        status: .failed,
                        replyToId: messages[index].replyToId,
                        replyToSnippet: messages[index].replyToSnippet,
                        reactions: messages[index].reactions,
                        createdAt: messages[index].createdAt
                    )
                }
                errorMessage = error.userMessage
                isSending = false

                // Enqueue failed message for offline retry
                if let index = messages.firstIndex(where: { $0.id == tempId }) {
                    let failedMessage = messages[index]
                    let sendActionData: SendActionData
                    switch failedMessage.content {
                    case .text(let text):
                        sendActionData = .text(text, replyToId: failedMessage.replyToId)
                    case .image(let url):
                        sendActionData = .image(url, replyToId: failedMessage.replyToId)
                    case .video(let url, let thumbnailURL):
                        sendActionData = .video(url, thumbnailURL: thumbnailURL, replyToId: failedMessage.replyToId)
                    case .audio(let url, let duration):
                        sendActionData = .audio(url, duration: duration, replyToId: failedMessage.replyToId)
                    case .like:
                        sendActionData = .like(failedMessage.replyToId)
                    default:
                        sendActionData = .text("", replyToId: failedMessage.replyToId)
                    }

                    let queuedMessage = QueuedMessage(
                        id: failedMessage.id,
                        conversationId: failedMessage.conversationId,
                        content: failedMessage.content,
                        replyToId: failedMessage.replyToId,
                        replyToSnippet: failedMessage.replyToSnippet,
                        createdAt: failedMessage.createdAt,
                        sendActionData: sendActionData
                    )
                    OfflineMessageQueue.shared.enqueue(queuedMessage)
                }
            }
        }
    }

    func sendLikeReaction() async {
        await MainActor.run { isSending = true }

        let tempId = UUID().uuidString
        let optimisticMessage = Message(
            id: tempId,
            conversationId: conversationId,
            sender: User(
                id: currentUserId,
                username: "me",
                fullName: "Me",
                email: nil,
                phone: nil,
                avatarURL: nil,
                bio: nil,
                website: nil,
                isVerified: false,
                isPrivate: false,
                followersCount: 0,
                followingCount: 0,
                postsCount: 0,
                createdAt: .now,
                isFollowing: false,
                isFollowedBy: false,
                isBlocked: false
            ),
            content: .like,
            status: .sending,
            replyToId: nil,
            replyToSnippet: nil,
            reactions: [:],
            createdAt: Date()
        )

        await MainActor.run {
            pendingMessages.insert(tempId)
            messages.append(optimisticMessage)
            isSending = false
        }

        do {
            let input = SendMessageInput(
                conversationId: conversationId,
                content: .like
            )
            let serverMessage = try await sendMessageUseCase.execute(input)

            await MainActor.run {
                if let index = messages.firstIndex(where: { $0.id == tempId }) {
                    messages[index] = serverMessage
                } else if !messages.contains(where: { $0.id == serverMessage.id }) {
                    messages.append(serverMessage)
                }
                pendingMessages.remove(tempId)
            }
        } catch {
            await MainActor.run {
                if let index = messages.firstIndex(where: { $0.id == tempId }) {
                    messages[index] = Message(
                        id: messages[index].id,
                        conversationId: messages[index].conversationId,
                        sender: messages[index].sender,
                        content: messages[index].content,
                        status: .failed,
                        replyToId: messages[index].replyToId,
                        replyToSnippet: messages[index].replyToSnippet,
                        reactions: messages[index].reactions,
                        createdAt: messages[index].createdAt
                    )
                }
                errorMessage = error.userMessage
                isSending = false

                // Enqueue failed message for offline retry
                if let index = messages.firstIndex(where: { $0.id == tempId }) {
                    let failedMessage = messages[index]
                    let sendActionData: SendActionData
                    switch failedMessage.content {
                    case .text(let text):
                        sendActionData = .text(text, replyToId: failedMessage.replyToId)
                    case .image(let url):
                        sendActionData = .image(url, replyToId: failedMessage.replyToId)
                    case .video(let url, let thumbnailURL):
                        sendActionData = .video(url, thumbnailURL: thumbnailURL, replyToId: failedMessage.replyToId)
                    case .audio(let url, let duration):
                        sendActionData = .audio(url, duration: duration, replyToId: failedMessage.replyToId)
                    case .like:
                        sendActionData = .like(failedMessage.replyToId)
                    default:
                        sendActionData = .text("", replyToId: failedMessage.replyToId)
                    }

                    let queuedMessage = QueuedMessage(
                        id: failedMessage.id,
                        conversationId: failedMessage.conversationId,
                        content: failedMessage.content,
                        replyToId: failedMessage.replyToId,
                        replyToSnippet: failedMessage.replyToSnippet,
                        createdAt: failedMessage.createdAt,
                        sendActionData: sendActionData
                    )
                    OfflineMessageQueue.shared.enqueue(queuedMessage)
                }
            }
        }
    }

    /// Retry sending all queued offline messages
    func retryQueuedMessages() async {
        await OfflineMessageQueue.shared.processQueue()
    }

    func unblockPartner() {
        // TODO: Implement unblock API call
        isPartnerBlocked = false
    }

    func markAsRead() {
        Task {
            do {
                try await manageMessageUseCase.markAsRead(conversationId: conversationId)
            } catch {
                // Silently fail - not critical
            }
        }
    }

    func startTyping() {
        chatSyncService.startTyping()
    }

    func stopTyping() {
        chatSyncService.stopTyping()
    }

    // MARK: - Incoming Message Handlers

    private func handleIncomingMessage(_ message: Message) {
        // Skip if it's our own optimistic message (by temp ID)
        if pendingMessages.contains(message.id) { return }

        // Skip if already exists (by server ID)
        if messages.contains(where: { $0.id == message.id }) { return }

        // Insert in chronological order
        let insertIndex = messages.firstIndex { $0.createdAt > message.createdAt } ?? messages.count
        messages.insert(message, at: insertIndex)

        // Preload media for the incoming message
        preloadMedia(for: [message])
    }

    private func handleMessageRead(userId: String) {
        // Update status of messages sent by us that are now read by partner
        for (index, message) in messages.enumerated() where message.sender.id == currentUserId {
            if message.status == .delivered || message.status == .sent {
                messages[index] = Message(
                    id: message.id,
                    conversationId: message.conversationId,
                    sender: message.sender,
                    content: message.content,
                    status: .read,
                    replyToId: message.replyToId,
                    replyToSnippet: message.replyToSnippet,
                    reactions: message.reactions,
                    createdAt: message.createdAt
                )
            }
        }
    }

    private func handleMessageDeleted(messageId: String) {
        messages.removeAll { $0.id == messageId }
    }

    // MARK: - Helpers

    private func mergeMessages(existing: [Message], new: [Message]) -> [Message] {
        var merged = existing
        for message in new {
            if !merged.contains(where: { $0.id == message.id }) {
                merged.append(message)
            }
        }
        // Sort by creation date
        merged.sort { $0.createdAt < $1.createdAt }
        return merged
    }
}

// MARK: - MessageContent Extension

private extension MessageContent {
    var textContent: String? {
        if case .text(let text) = self { return text }
        return nil
    }
}