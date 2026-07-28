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

    private(set) var users: [User] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var searchQuery = ""

    let postId: String

    // MARK: - Dependencies

    private let userRepository: UserRepositoryProtocol
    private let toggleFollowUseCase: ToggleFollowUseCaseProtocol

    // MARK: - Init

    init(
        postId: String,
        userRepository: UserRepositoryProtocol,
        toggleFollowUseCase: ToggleFollowUseCaseProtocol
    ) {
        self.postId = postId
        self.userRepository = userRepository
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
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            // Use suggested users as mock "likes" list
            // Real implementation would have a dedicated endpoint: POST /posts/{id}/likes
            users = try await userRepository.fetchSuggested(page: 1, perPage: 50)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleFollow(for user: User) async {
        guard let index = users.firstIndex(where: { $0.id == user.id }) else { return }

        // Optimistic update
        var updated = users[index]
        updated.isFollowing.toggle()
        users[index] = updated

        do {
            try await toggleFollowUseCase.execute(
                ToggleFollowInput(userId: user.id, isCurrentlyFollowing: user.isFollowing)
            )
        } catch {
            users[index] = user
        }
    }
}
