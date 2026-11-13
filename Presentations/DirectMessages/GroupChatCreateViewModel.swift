//
//  GroupChatCreateViewModel.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation
import Observation
import UIKit

// MARK: - GroupChatCreateViewModel

@MainActor
@Observable
final class GroupChatCreateViewModel {

    // MARK: - State
    var searchQuery = ""
    var selectedUsers: [User] = []
    var suggestedUsers: [User] = []
    var filteredUsers: [User] = []
    var isLoading = false
    var isCreated = false
    var errorMessage: String?

    // MARK: - Dependencies
    private let groupChatUseCase: GroupChatUseCaseProtocol

    // MARK: - Init
    init(
        groupChatUseCase: GroupChatUseCaseProtocol
    ) {
        self.groupChatUseCase = groupChatUseCase
    }

    // MARK: - Computed
    var canCreate: Bool {
        selectedUsers.count >= 2
    }

    // MARK: - Actions
    func toggleUserSelection(_ user: User) {
        if let index = selectedUsers.firstIndex(where: { $0.id == user.id }) {
            selectedUsers.remove(at: index)
        } else {
            selectedUsers.append(user)
        }
        // Refresh filtered list to update selection state
        applyFilter()
    }

    func applyFilter() {
        if searchQuery.isEmpty {
            filteredUsers = []
        } else {
            // Filter suggested users based on search query
            filteredUsers = suggestedUsers.filter {
                $0.username.localizedCaseInsensitiveContains(searchQuery) ||
                $0.fullName.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    func createGroup() async {
        guard canCreate else { return }

        isLoading = true
        errorMessage = nil

        do {
            let participantIds = selectedUsers.map { $0.id }
            _ = try await groupChatUseCase.createGroup(
                participantIds: participantIds,
                name: nil // Will be auto-generated or set later
            )
            isCreated = true
            HapticFeedbackSafe.notification(.success)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
