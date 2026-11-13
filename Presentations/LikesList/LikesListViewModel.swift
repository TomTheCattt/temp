//
//  LikesListViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - LikesListViewModel

@MainActor
@Observable
final class LikesListViewModel {

    // MARK: - State

    var users: [User] = []
    var isLoading = false
    var errorMessage: String?
    var searchQuery = ""

    let postId: String

    // MARK: - Dependencies

    private let toggleFollowUseCase: ToggleFollowUseCaseProtocol

    // MARK: - Init

    init(
        postId: String,
        toggleFollowUseCase: ToggleFollowUseCaseProtocol
    ) {
        self.postId = postId
        self.toggleFollowUseCase = toggleFollowUseCase
    }

    // MARK: - Computed

    var filteredUsers: [User] {
        if searchQuery.isEmpty { return users }
        let query = searchQuery.lowercased()
        return users.filter {
            $0.username.lowercased().contains(query) ||
            $0.fullName.lowercased().contains(query)
        }
    }

    // MARK: - Actions

    func loadLikes() async {
        // TODO: Implement loadLikes logic from scratch
    }

    func toggleFollow(for user: User) async {
        _ = user
        // TODO: Implement toggleFollow logic from scratch
    }
}
