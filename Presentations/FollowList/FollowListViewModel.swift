//
//  FollowListViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - FollowListMode

enum FollowListMode {
    case followers
    case following
}

// MARK: - FollowListViewModel

@MainActor
@Observable
final class FollowListViewModel {

    // MARK: - State

    var users: [User] = []
    var isLoading = false
    var errorMessage: String?
    var searchQuery = ""

    let userId: String
    let mode: FollowListMode

    // MARK: - Dependencies

    private let fetchFollowersUseCase: FetchFollowersUseCaseProtocol
    private let fetchFollowingUseCase: FetchFollowingUseCaseProtocol
    private let toggleFollowUseCase: ToggleFollowUseCaseProtocol

    // MARK: - Init

    init(
        userId: String,
        mode: FollowListMode,
        fetchFollowersUseCase: FetchFollowersUseCaseProtocol,
        fetchFollowingUseCase: FetchFollowingUseCaseProtocol,
        toggleFollowUseCase: ToggleFollowUseCaseProtocol
    ) {
        self.userId = userId
        self.mode = mode
        self.fetchFollowersUseCase = fetchFollowersUseCase
        self.fetchFollowingUseCase = fetchFollowingUseCase
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

    var title: String {
        mode == .followers ? L10n.Profile.followers : L10n.Profile.following
    }

    // MARK: - Actions

    func loadUsers() async {
        // TODO: Implement loadUsers logic from scratch
    }

    func loadMore() async {
        // TODO: Implement loadMore follow list logic from scratch
    }

    func toggleFollow(for user: User) async {
        _ = user
        // TODO: Implement toggleFollow logic from scratch
    }
}
