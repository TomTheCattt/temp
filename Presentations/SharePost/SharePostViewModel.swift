//
//  SharePostViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation
import UIKit

// MARK: - SharePostViewModel

@MainActor
@Observable
final class SharePostViewModel {

    // MARK: - State

    private(set) var users: [User] = []
    private(set) var isLoading = false
    var selectedUserIds: Set<String> = []

    let postId: String

    // MARK: - Dependencies

    private let userRepository: UserRepositoryProtocol
    private let messageRepository: MessageRepositoryProtocol

    // MARK: - Init

    init(
        postId: String,
        userRepository: UserRepositoryProtocol,
        messageRepository: MessageRepositoryProtocol
    ) {
        self.postId = postId
        self.userRepository = userRepository
        self.messageRepository = messageRepository
    }

    // MARK: - Actions

    func loadUsers() async {
        guard !isLoading else { return }
        isLoading = true

        do {
            // Load recent/suggested users to share with
            users = try await userRepository.fetchSuggested(page: 1, perPage: 20)
        } catch {
            // Silent fail
        }

        isLoading = false
    }

    func filteredUsers(query: String) -> [User] {
        if query.isEmpty { return users }
        let q = query.lowercased()
        return users.filter {
            $0.username.lowercased().contains(q) ||
            $0.fullName.lowercased().contains(q)
        }
    }

    func toggleUser(_ userId: String) {
        if selectedUserIds.contains(userId) {
            selectedUserIds.remove(userId)
        } else {
            selectedUserIds.insert(userId)
        }
    }

    func sendToSelected() async {
        // Send post as message to each selected user
        for userId in selectedUserIds {
            do {
                // Create or find conversation, then send post
                let conversation = try await messageRepository.createConversation(participantIds: [userId])
                _ = try await messageRepository.sendMessage(
                    conversationId: conversation.id,
                    content: .post(postId: postId)
                )
            } catch {
                // Silent fail per user
            }
        }
    }

    func copyLink() {
        // Copy post link to clipboard
        let link = "https://instagram.com/p/\(postId)"
        UIPasteboard.general.string = link
    }
}
