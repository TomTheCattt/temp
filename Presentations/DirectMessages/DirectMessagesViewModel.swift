//
//  DirectMessagesViewModel.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Combine

// MARK: - DirectMessagesViewModel

@MainActor
@Observable
final class DirectMessagesViewModel {

    // MARK: - State

    private(set) var conversations: [Conversation] = []
    private(set) var notes: [InstagramNote] = []
    private(set) var isLoading = false

    var searchQuery = ""

    // MARK: - Filtered Conversations

    var filteredConversations: [Conversation] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return conversations }

        let lower = trimmed.lowercased()
        let currentUserId = SessionStore.shared.currentUserId
        return conversations.filter { conv in
            let otherUser = conv.participants.first { $0.id != currentUserId && $0.id != MockData.currentUser.id && $0.id != "user_current" }
                ?? conv.participants.first { $0.id != currentUserId }
                ?? conv.participants.first
            let usernameMatch = otherUser?.username.lowercased().contains(lower) ?? false
            let fullNameMatch = otherUser?.fullName.lowercased().contains(lower) ?? false
            let groupMatch = conv.groupName?.lowercased().contains(lower) ?? false
            return usernameMatch || fullNameMatch || groupMatch
        }
    }

    // MARK: - Dependencies

    private let messageRepository: MessageRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(messageRepository: MessageRepositoryProtocol) {
        self.messageRepository = messageRepository
        subscribeToSyncUpdates()
    }

    private func subscribeToSyncUpdates() {
        NotificationCenter.default.publisher(for: .didUpdateConversations)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshFromLocal()
            }
            .store(in: &cancellables)
    }

    private var refreshTask: Task<Void, Never>?

    func refreshFromLocal() {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor [weak self] in
            guard let self else { return }
            if let convs = try? await self.messageRepository.fetchConversations(page: 1, perPage: 30) {
                guard !Task.isCancelled else { return }
                self.conversations = convs
            }
        }
    }

    // MARK: - Actions

    func loadConversations() async {
        guard !isLoading else { return }
        isLoading = true

        let clock = ContinuousClock()
        let startTime = clock.now

        async let convsTask = messageRepository.fetchConversations(page: 1, perPage: 30)
        async let notesTask = messageRepository.fetchNotes()

        do {
            let (fetchedConvs, fetchedNotes) = try await (convsTask, notesTask)
            conversations = fetchedConvs
            notes = fetchedNotes

            let duration = clock.now - startTime
            print("[Benchmark] DirectMessagesViewModel.loadData executed in \(duration) (\(conversations.count) conversations, \(notes.count) notes)")
        } catch {
            // Fallback load
            if let convs = try? await messageRepository.fetchConversations(page: 1, perPage: 30) {
                conversations = convs
            }
        }

        isLoading = false
    }

    func markAsRead(conversationId: String) async {
        do {
            try await messageRepository.markAsRead(conversationId: conversationId)
            if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                let conv = conversations[index]
                conversations[index] = Conversation(
                    id: conv.id,
                    participants: conv.participants,
                    lastMessage: conv.lastMessage,
                    unreadCount: 0,
                    isGroup: conv.isGroup,
                    groupName: conv.groupName,
                    groupAvatarURL: conv.groupAvatarURL,
                    updatedAt: conv.updatedAt,
                    isMuted: conv.isMuted
                )
            }
        } catch {
            // Silent fail
        }
    }

    func deleteConversation(id: String) {
        conversations.removeAll { $0.id == id }
        Task {
            try? await messageRepository.deleteConversation(id: id)
        }
    }

    func toggleMute(id: String) {
        guard let index = conversations.firstIndex(where: { $0.id == id }) else { return }
        let current = conversations[index]
        let newMuted = !current.isMuted
        conversations[index] = Conversation(
            id: current.id,
            participants: current.participants,
            lastMessage: current.lastMessage,
            unreadCount: current.unreadCount,
            isGroup: current.isGroup,
            groupName: current.groupName,
            groupAvatarURL: current.groupAvatarURL,
            updatedAt: current.updatedAt,
            isMuted: newMuted
        )
        Task {
            try? await messageRepository.muteConversation(id: id, mute: newMuted)
        }
    }

    func toggleUnread(id: String) {
        guard let index = conversations.firstIndex(where: { $0.id == id }) else { return }
        let current = conversations[index]
        let newCount = current.unreadCount > 0 ? 0 : 1
        conversations[index] = Conversation(
            id: current.id,
            participants: current.participants,
            lastMessage: current.lastMessage,
            unreadCount: newCount,
            isGroup: current.isGroup,
            groupName: current.groupName,
            groupAvatarURL: current.groupAvatarURL,
            updatedAt: current.updatedAt,
            isMuted: current.isMuted
        )
        Task {
            if newCount == 0 {
                try? await messageRepository.markAsRead(conversationId: id)
            } else {
                try? await messageRepository.markAsUnread(conversationId: id)
            }
        }
    }

    func addOrUpdateNote(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let currentUser = SessionStore.shared.currentUser ?? User(
            id: SessionStore.shared.currentUserId.isEmpty ? "user_current" : SessionStore.shared.currentUserId,
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
        let newNote = InstagramNote(
            id: "note_current_\(UUID().uuidString.prefix(6))",
            user: currentUser,
            text: trimmed,
            createdAt: .now,
            isCurrentUser: true
        )
        // Replace existing current user note if present
        if let index = notes.firstIndex(where: { $0.isCurrentUser }) {
            notes[index] = newNote
        } else {
            notes.insert(newNote, at: 0)
        }
    }
}
