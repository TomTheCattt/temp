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

    private(set) var messages: [Message] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var isSending = false
    private(set) var errorMessage: String?

    private(set) var currentPage = 1
    private(set) var hasMorePages = true

    var recipient: User?
    var replyingToMessage: Message?
    var isPartnerTyping: Bool = false
    var isPartnerBlocked: Bool = false

    let conversationId: String

    /// Resolved current user id. Falls back to the shared session store when the
    /// injected value is empty so bubbles don't all render as incoming.
    var currentUserId: String {
        let storeId = SessionStore.shared.currentUserId
        if !storeId.isEmpty { return storeId }
        return injectedCurrentUserId
    }

    private var resolvedCurrentUser: User {
        SessionStore.shared.currentUser ?? User(
            id: currentUserId,
            username: "user",
            fullName: "User",
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
        )
    }

    private let injectedCurrentUserId: String

    /// Page size used for every fetch. Keeps `hasMorePages` math consistent.
    private let perPage = DS.Layout.messagesPageSize

    // MARK: - Dependencies

    private let fetchMessagesUseCase: FetchMessagesUseCaseProtocol
    private let sendMessageUseCase: SendMessageUseCaseProtocol
    private let messageRepository: MessageRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

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

        subscribeToSyncEvents()
    }

    private func subscribeToSyncEvents() {
        // Real-time incoming messages with chronological sorting
        NotificationCenter.default.publisher(for: .didUpdateMessage)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self = self,
                      let message = notification.object as? Message,
                      message.conversationId == self.conversationId else { return }

                let updated = self.deduplicateAndSort(self.messages + [message])
                if updated.count != self.messages.count || updated != self.messages {
                    self.messages = updated
                    self.markAsRead()
                }
            }
            .store(in: &cancellables)

        // Real-time typing status
        NotificationCenter.default.publisher(for: .didUpdateTypingStatus)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let convId = userInfo["conversationId"] as? String,
                      convId == self.conversationId,
                      let isTyping = userInfo["isTyping"] as? Bool else { return }

                self.isPartnerTyping = isTyping
            }
            .store(in: &cancellables)

        // Real-time block status
        NotificationCenter.default.publisher(for: .didUpdateBlockStatus)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let userId = userInfo["userId"] as? String,
                      userId == self.recipient?.id,
                      let isBlocked = userInfo["isBlocked"] as? Bool else { return }

                self.isPartnerBlocked = isBlocked
            }
            .store(in: &cancellables)
    }

    func unblockPartner() {
        guard let user = recipient else { return }
        isPartnerBlocked = false
        NotificationCenter.default.post(
            name: .didUpdateBlockStatus,
            object: nil,
            userInfo: ["userId": user.id, "isBlocked": false]
        )
        ToastManager.shared.info("Đã bỏ chặn @\(user.username)")
    }

    func markAsRead() {
        Task {
            try? await messageRepository.markAsRead(conversationId: conversationId)
        }
    }

    // MARK: - Lifecycle & Cooperative Cancellation

    func onAppear() {
        if cancellables.isEmpty {
            subscribeToSyncEvents()
        }
    }

    func onDisappear() {
        cancellables.removeAll()
        let repo = messageRepository
        let convId = conversationId
        Task {
            await repo.detachMessageListener(for: convId)
        }
    }

    deinit {
        let repo = messageRepository
        let convId = conversationId
        Task {
            await repo.detachMessageListener(for: convId)
        }
    }

    // MARK: - Actions

    func loadMessages() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        currentPage = 1

        let clock = ContinuousClock()
        let startTime = clock.now

        do {
            let result = try await fetchMessagesUseCase.execute(
                FetchMessagesInput(conversationId: conversationId, page: 1, perPage: perPage)
            )
            messages = deduplicateAndSort(result)
            hasMorePages = result.count >= perPage

            // Resolve recipient if not provided
            if recipient == nil {
                if let otherUser = messages.first(where: { $0.sender.id != currentUserId })?.sender {
                    recipient = otherUser
                }
            }

            // Benchmark execution time
            let duration = clock.now - startTime
            print("[Benchmark] ChatViewModel.loadMessages executed in \(duration) for \(messages.count) messages")

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
        let clock = ContinuousClock()
        let startTime = clock.now

        do {
            let result = try await fetchMessagesUseCase.execute(
                FetchMessagesInput(conversationId: conversationId, page: nextPage, perPage: perPage)
            )
            currentPage = nextPage
            // Fewer than a full page means there's no more history.
            hasMorePages = result.count >= perPage
            mergeOlderMessages(result)

            let duration = clock.now - startTime
            print("[Benchmark] ChatViewModel.loadMoreMessages (page \(nextPage)) executed in \(duration)")
        } catch {
            // Don't retry silently in a loop: stop further auto-triggers and
            // surface the error since we already have messages on screen.
            hasMorePages = false
            ToastManager.shared.error(error.userMessage)
        }

        isLoadingMore = false
    }

    func sendTextMessage(_ text: String) async {
        guard !isSending, !isPartnerBlocked else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true

        let replyId = replyingToMessage?.id
        let replySnippet: String? = {
            guard let reply = replyingToMessage else { return nil }
            switch reply.content {
            case .text(let t): return t
            case .image: return "Hình ảnh"
            case .video: return "Video"
            case .audio: return "Tin nhắn thoại"
            case .post: return "Bài viết"
            case .reel: return "Reel"
            case .story: return "Tin"
            case .like: return "❤️"
            }
        }()

        // Clear reply bar immediately on send
        replyingToMessage = nil

        // Optimistic UI: insert pending message with .sending status
        let tempId = "temp_\(UUID().uuidString.prefix(8))"
        let currentUser = SessionStore.shared.currentUser ?? User(
            id: currentUserId,
            username: AppConstants.TestAccount.username,
            fullName: AppConstants.TestAccount.fullName,
            email: AppConstants.TestAccount.email,
            phone: nil,
            avatarURL: nil,
            bio: nil,
            website: nil,
            isVerified: true,
            isPrivate: false,
            followersCount: 0,
            followingCount: 0,
            postsCount: 0,
            createdAt: .now,
            isFollowing: false,
            isFollowedBy: false,
            isBlocked: false
        )
        let pendingMessage = Message(
            id: tempId,
            conversationId: conversationId,
            sender: currentUser,
            content: .text(trimmed),
            status: .sending,
            replyToId: replyId,
            replyToSnippet: replySnippet,
            reactions: [:],
            createdAt: .now
        )
        messages.insert(pendingMessage, at: 0)

        do {
            let message = try await sendMessageUseCase.execute(
                SendMessageInput(
                    conversationId: conversationId,
                    content: .text(trimmed),
                    replyToId: replyId,
                    replyToSnippet: replySnippet
                )
            )
            // Replace optimistic pending message with confirmed message
            let finalMessage = Message(
                id: message.id,
                conversationId: message.conversationId,
                sender: message.sender,
                content: message.content,
                status: message.status,
                replyToId: replyId,
                replyToSnippet: replySnippet,
                reactions: [:],
                createdAt: message.createdAt
            )
            if let index = messages.firstIndex(where: { $0.id == tempId }) {
                messages.remove(at: index)
            }
            messages = deduplicateAndSort(messages + [finalMessage])
            simulateReadReceipt(for: message.id)
            simulatePartnerTyping()
        } catch {
            // Update the pending message to .failed state so user can retry
            if let index = messages.firstIndex(where: { $0.id == tempId }) {
                let current = messages[index]
                messages[index] = Message(
                    id: current.id,
                    conversationId: current.conversationId,
                    sender: current.sender,
                    content: current.content,
                    status: .failed,
                    replyToId: current.replyToId,
                    replyToSnippet: current.replyToSnippet,
                    reactions: current.reactions,
                    createdAt: current.createdAt
                )
            }
            ToastManager.shared.error("Không thể gửi tin nhắn. Chạm để thử lại.")
        }

        isSending = false
    }

    /// Retry sending a failed message
    func retryMessage(id: String) async {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        let current = messages[index]
        guard current.status == .failed else { return }

        // Set status to sending
        messages[index] = Message(
            id: current.id,
            conversationId: current.conversationId,
            sender: current.sender,
            content: current.content,
            status: .sending,
            replyToId: current.replyToId,
            replyToSnippet: current.replyToSnippet,
            reactions: current.reactions,
            createdAt: current.createdAt
        )

        do {
            let message = try await sendMessageUseCase.execute(
                SendMessageInput(
                    conversationId: conversationId,
                    content: current.content,
                    replyToId: current.replyToId,
                    replyToSnippet: current.replyToSnippet
                )
            )
            if let newIndex = messages.firstIndex(where: { $0.id == id }) {
                messages[newIndex] = Message(
                    id: message.id,
                    conversationId: message.conversationId,
                    sender: message.sender,
                    content: message.content,
                    status: message.status,
                    replyToId: current.replyToId,
                    replyToSnippet: current.replyToSnippet,
                    reactions: [:],
                    createdAt: message.createdAt
                )
                simulateReadReceipt(for: message.id)
            }
        } catch {
            if let newIndex = messages.firstIndex(where: { $0.id == id }) {
                let failed = messages[newIndex]
                messages[newIndex] = Message(
                    id: failed.id,
                    conversationId: failed.conversationId,
                    sender: failed.sender,
                    content: failed.content,
                    status: .failed,
                    replyToId: failed.replyToId,
                    replyToSnippet: failed.replyToSnippet,
                    reactions: failed.reactions,
                    createdAt: failed.createdAt
                )
            }
            ToastManager.shared.error("Gửi lại thất bại. Vui lòng kiểm tra kết nối mạng.")
        }
    }

    func addReaction(to messageId: String, emoji: String) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }
        let current = messages[index]
        var updatedReactions = current.reactions
        if updatedReactions[currentUserId] == emoji {
            updatedReactions.removeValue(forKey: currentUserId)
        } else {
            updatedReactions[currentUserId] = emoji
        }

        messages[index] = Message(
            id: current.id,
            conversationId: current.conversationId,
            sender: current.sender,
            content: current.content,
            status: current.status,
            replyToId: current.replyToId,
            replyToSnippet: current.replyToSnippet,
            reactions: updatedReactions,
            createdAt: current.createdAt
        )

        Task {
            try? await messageRepository.addReaction(messageId: messageId, emoji: emoji)
        }
    }

    func deleteMessage(id: String) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages.remove(at: index)
        Task {
            try? await messageRepository.deleteMessage(id: id)
            NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
        }
    }

    func sendImageMessage(url: URL) async {
        guard !isSending else { return }
        isSending = true

        let tempId = "temp_img_\(UUID().uuidString.prefix(8))"
        let currentUser = resolvedCurrentUser
        let pendingMessage = Message(
            id: tempId,
            conversationId: conversationId,
            sender: currentUser,
            content: .image(url),
            status: .sending,
            replyToId: nil,
            replyToSnippet: nil,
            reactions: [:],
            createdAt: .now
        )
        messages.insert(pendingMessage, at: 0)

        do {
            let message = try await sendMessageUseCase.execute(
                SendMessageInput(conversationId: conversationId, content: .image(url))
            )
            if let index = messages.firstIndex(where: { $0.id == tempId }) {
                messages.remove(at: index)
            }
            messages = deduplicateAndSort(messages + [message])
            simulateReadReceipt(for: message.id)
        } catch {
            if let index = messages.firstIndex(where: { $0.id == tempId }) {
                let current = messages[index]
                messages[index] = Message(
                    id: current.id,
                    conversationId: current.conversationId,
                    sender: current.sender,
                    content: current.content,
                    status: .failed,
                    replyToId: current.replyToId,
                    replyToSnippet: current.replyToSnippet,
                    reactions: current.reactions,
                    createdAt: current.createdAt
                )
            }
            ToastManager.shared.error(error.userMessage)
        }

        isSending = false
    }

    func sendLikeReaction() async {
        guard !isSending else { return }
        isSending = true

        let tempId = "temp_like_\(UUID().uuidString.prefix(8))"
        let currentUser = resolvedCurrentUser
        let pendingMessage = Message(
            id: tempId,
            conversationId: conversationId,
            sender: currentUser,
            content: .like,
            status: .sending,
            replyToId: nil,
            replyToSnippet: nil,
            reactions: [:],
            createdAt: .now
        )
        messages.insert(pendingMessage, at: 0)

        do {
            let message = try await sendMessageUseCase.execute(
                SendMessageInput(conversationId: conversationId, content: .like)
            )
            if let index = messages.firstIndex(where: { $0.id == tempId }) {
                messages.remove(at: index)
            }
            messages = deduplicateAndSort(messages + [message])
            simulateReadReceipt(for: message.id)
        } catch {
            messages.removeAll { $0.id == tempId }
            ToastManager.shared.error(error.userMessage)
        }

        isSending = false
    }

    // MARK: - Draft restoration

    /// Set by the view to restore unsent text into the input field when a send fails.
    var restoreDraft: ((String) -> Void)?

    // MARK: - Private helpers

    /// Merge an older page into `messages`, keeping existing entries and deduplicating.
    private func mergeOlderMessages(_ older: [Message]) {
        guard !older.isEmpty else { return }
        messages = deduplicateAndSort(messages + older)
    }

    /// Smart deduplication based on ID and message fingerprint (sender + content + time window).
    private func deduplicateAndSort(_ list: [Message]) -> [Message] {
        var seenIds = Set<String>()
        var seenFingerprints = Set<String>()
        var result: [Message] = []

        for msg in list {
            if seenIds.contains(msg.id) { continue }

            let contentKey = msg.content.fingerprintRepresentation
            let timeBucket = Int(msg.createdAt.timeIntervalSince1970 / 3.0)
            let fingerprint = "\(msg.sender.id)_\(contentKey)_\(timeBucket)"

            if seenFingerprints.contains(fingerprint) {
                // If existing entry has a temporary or fallback placeholder ID, replace it with real ID
                if let existingIdx = result.firstIndex(where: {
                    let existingBucket = Int($0.createdAt.timeIntervalSince1970 / 3.0)
                    return $0.sender.id == msg.sender.id &&
                           $0.content.fingerprintRepresentation == contentKey &&
                           existingBucket == timeBucket
                }) {
                    let existingId = result[existingIdx].id
                    if existingId.starts(with: "temp_") || existingId == "last" || existingId.hasSuffix("_last") {
                        seenIds.remove(existingId)
                        result[existingIdx] = msg
                        seenIds.insert(msg.id)
                    }
                }
                continue
            }

            seenIds.insert(msg.id)
            seenFingerprints.insert(fingerprint)
            result.append(msg)
        }
        return result.sorted { $0.createdAt > $1.createdAt }
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
                replyToSnippet: current.replyToSnippet,
                reactions: current.reactions,
                createdAt: current.createdAt
            )
        }
    }

    /// Mock-friendly partner typing simulator.
    private func simulatePartnerTyping() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard let self else { return }
            self.isPartnerTyping = true
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            self.isPartnerTyping = false
        }
    }
}

// MARK: - MessageContent Fingerprint Helper

private extension MessageContent {
    var fingerprintRepresentation: String {
        switch self {
        case .text(let text): return "text:\(text)"
        case .image(let url): return "image:\(url.absoluteString)"
        case .video(let url, _): return "video:\(url.absoluteString)"
        case .audio(let url, _): return "audio:\(url.absoluteString)"
        case .post(let id): return "post:\(id)"
        case .story(let id): return "story:\(id)"
        case .reel(let id): return "reel:\(id)"
        case .like: return "like"
        }
    }
}

