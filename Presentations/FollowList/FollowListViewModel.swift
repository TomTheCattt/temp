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

    private(set) var users: [User] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var searchQuery = ""

    private var currentPage = 1
    private var hasMorePages = true

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
        mode == .followers ? "Followers" : "Following"
    }

    // MARK: - Actions

    func loadUsers() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        currentPage = 1

        do {
            let input = FetchFollowListInput(userId: userId, page: 1)
            let result: [User]
            switch mode {
            case .followers:
                result = try await fetchFollowersUseCase.execute(input)
            case .following:
                result = try await fetchFollowingUseCase.execute(input)
            }
            users = result
            hasMorePages = result.count >= 30
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadMore() async {
        guard !isLoading, hasMorePages else { return }
        isLoading = true

        let nextPage = currentPage + 1
        do {
            let input = FetchFollowListInput(userId: userId, page: nextPage)
            let result: [User]
            switch mode {
            case .followers:
                result = try await fetchFollowersUseCase.execute(input)
            case .following:
                result = try await fetchFollowingUseCase.execute(input)
            }
            users.append(contentsOf: result)
            currentPage = nextPage
            hasMorePages = result.count >= 30
        } catch {
            // Silent fail
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
            if user.isFollowing {
                try await toggleFollowUseCase.execute(
                    ToggleFollowInput(userId: user.id, isCurrentlyFollowing: true)
                )
            } else {
                try await toggleFollowUseCase.execute(
                    ToggleFollowInput(userId: user.id, isCurrentlyFollowing: false)
                )
            }
        } catch {
            // Revert
            users[index] = user
        }
    }
}
