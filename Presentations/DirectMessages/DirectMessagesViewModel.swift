//
//  DirectMessagesViewModel.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - DirectMessagesViewModel

@MainActor
@Observable
final class DirectMessagesViewModel {

    // MARK: - State

    var conversations: [Conversation] = []
    var notes: [InstagramNote] = []
    var isLoading = false
    var searchQuery = ""
    var errorMessage: String?

    // MARK: - Filter State

    enum ConversationFilter: CaseIterable {
        case all
        case unread
        case groups
        case media

        var title: String {
            switch self {
            case .all: return "Tất cả"
            case .unread: return "Chưa đọc"
            case .groups: return "Nhóm"
            case .media: return "Media"
            }
        }

        var icon: String {
            switch self {
            case .all: return "tray.full"
            case .unread: return "envelope.badge"
            case .groups: return "person.3"
            case .media: return "photo.on.rectangle"
            }
        }
    }

    var selectedFilter: ConversationFilter = .all

    // MARK: - Pagination

    private var currentPage = 1
    private let perPage = 20
    private var hasMorePages = true

    // MARK: - Filtered Conversations

    var filteredConversations: [Conversation] {
        var result = conversations

        // Apply selected filter
        switch selectedFilter {
        case .all:
            break
        case .unread:
            result = result.filter { $0.unreadCount > 0 }
        case .groups:
            result = result.filter { $0.isGroup }
        case .media:
            result = result.filter { conv in
                guard let lastMessage = conv.lastMessage else { return false }
                switch lastMessage.content {
                case .image, .video, .audio, .post, .story, .reel:
                    return true
                default:
                    return false
                }
            }
        }

        // Apply search query
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return result }

        let lower = trimmed.lowercased()
        let currentUserId = SessionStore.shared.currentUserId
        return result.filter { conv in
            let otherUser = conv.participants.first { $0.id != currentUserId }
                ?? conv.participants.first
            let usernameMatch = otherUser?.username.lowercased().contains(lower) ?? false
            let fullNameMatch = otherUser?.fullName.lowercased().contains(lower) ?? false
            let groupMatch = conv.groupName?.lowercased().contains(lower) ?? false
            return usernameMatch || fullNameMatch || groupMatch
        }
    }

    // MARK: - Dependencies

    private let messageRepository: MessageRepositoryProtocol

    // MARK: - Init

    init(messageRepository: MessageRepositoryProtocol) {
        self.messageRepository = messageRepository
    }

    // MARK: - Sync & Refresh

    /// Refresh conversations from local cache (called on app foreground, pull-to-refresh)
    func refreshFromLocal() {
        // Reset pagination and reload first page
        currentPage = 1
        hasMorePages = true
        Task {
            await loadConversations()
        }
    }

    // MARK: - Actions

    /// Load conversations with pagination
    func loadConversations() async {
        guard !isLoading, hasMorePages else { return }

        if currentPage == 1 {
            isLoading = true
            errorMessage = nil
        }

        do {
            let fetched = try await messageRepository.fetchConversations(page: currentPage, perPage: perPage)

            await MainActor.run {
                if currentPage == 1 {
                    conversations = fetched
                } else {
                    // Append new conversations, avoiding duplicates by id
                    let existingIds = Set(conversations.map { $0.id })
                    conversations.append(contentsOf: fetched.filter { !existingIds.contains($0.id) })
                }

                hasMorePages = fetched.count >= perPage
                currentPage += 1
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.userMessage
                isLoading = false
            }
        }
    }

    /// Load more conversations for pagination
    func loadMoreConversations() async {
        await loadConversations()
    }

    /// Mark conversation as read
    func markAsRead(conversationId: String) async {
        do {
            try await messageRepository.markAsRead(conversationId: conversationId)

            await MainActor.run {
                // Update local unread count
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
            }
        } catch {
            await MainActor.run {
                errorMessage = error.userMessage
            }
        }
    }

    /// Delete a conversation
    func deleteConversation(id: String) {
        Task {
            do {
                try await messageRepository.deleteConversation(id: id)

                await MainActor.run {
                    conversations.removeAll { $0.id == id }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.userMessage
                }
            }
        }
    }

    /// Toggle mute state for a conversation
    func toggleMute(id: String) {
        Task {
            guard let index = conversations.firstIndex(where: { $0.id == id }) else { return }
            let currentMuted = conversations[index].isMuted
            let newMuted = !currentMuted

            do {
                try await messageRepository.muteConversation(id: id, mute: newMuted)

                await MainActor.run {
                    let conv = conversations[index]
                    conversations[index] = Conversation(
                        id: conv.id,
                        participants: conv.participants,
                        lastMessage: conv.lastMessage,
                        unreadCount: conv.unreadCount,
                        isGroup: conv.isGroup,
                        groupName: conv.groupName,
                        groupAvatarURL: conv.groupAvatarURL,
                        updatedAt: conv.updatedAt,
                        isMuted: newMuted
                    )
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.userMessage
                }
            }
        }
    }

    /// Toggle unread state for a conversation
    func toggleUnread(id: String) {
        Task {
            guard let index = conversations.firstIndex(where: { $0.id == id }) else { return }
            let currentUnreadCount = conversations[index].unreadCount
            let newUnreadCount = currentUnreadCount > 0 ? 0 : 1

            // Use markAsRead or markAsUnread based on current state
            do {
                if newUnreadCount == 0 {
                    try await messageRepository.markAsRead(conversationId: id)
                } else {
                    try await messageRepository.markAsUnread(conversationId: id)
                }

                await MainActor.run {
                    let conv = conversations[index]
                    conversations[index] = Conversation(
                        id: conv.id,
                        participants: conv.participants,
                        lastMessage: conv.lastMessage,
                        unreadCount: newUnreadCount,
                        isGroup: conv.isGroup,
                        groupName: conv.groupName,
                        groupAvatarURL: conv.groupAvatarURL,
                        updatedAt: conv.updatedAt,
                        isMuted: conv.isMuted
                    )
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.userMessage
                }
            }
        }
    }

    /// Add or update a note for the current user
    func addOrUpdateNote(text: String) {
        Task {
            do {
                let note = try await messageRepository.saveNote(text: text)

                await MainActor.run {
                    // Update or insert the note
                    if let index = notes.firstIndex(where: { $0.isCurrentUser }) {
                        notes[index] = note
                    } else {
                        notes.insert(note, at: 0)
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.userMessage
                }
            }
        }
    }

    /// Load notes for the current user and following friends
    func loadNotes() async {
        do {
            let fetchedNotes = try await messageRepository.fetchNotes()

            await MainActor.run {
                notes = fetchedNotes
            }
        } catch {
            await MainActor.run {
                errorMessage = error.userMessage
            }
        }
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}