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

    var users: [User] = []
    var isLoading = false
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
        // TODO: Implement loadUsers logic from scratch
    }

    func filteredUsers(query: String) -> [User] {
        if query.isEmpty { return users }
        let q = query.lowercased()
        return users.filter {
            $0.username.lowercased().contains(q) ||
            $0.fullName.lowercased().contains(query)
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
        // TODO: Implement sendToSelected logic from scratch
    }

    func copyLink() {
        let link = "https://instagram.com/p/\(postId)"
        UIPasteboard.general.string = link
    }
}
