//
//  ProfileViewModel.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - ProfileViewModel

@MainActor
@Observable
final class ProfileViewModel {

    // MARK: - State

    private(set) var user: User?
    private(set) var posts: [Post] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    let isCurrentUser: Bool
    private let userId: String?

    // MARK: - Dependencies

    private let fetchProfileUseCase: FetchProfileUseCaseProtocol
    private let toggleFollowUseCase: ToggleFollowUseCaseProtocol
    private let postRepository: PostRepositoryProtocol

    // MARK: - Init

    init(
        userId: String?,
        fetchProfileUseCase: FetchProfileUseCaseProtocol,
        toggleFollowUseCase: ToggleFollowUseCaseProtocol,
        postRepository: PostRepositoryProtocol
    ) {
        self.userId = userId
        self.isCurrentUser = (userId == nil)
        self.fetchProfileUseCase = fetchProfileUseCase
        self.toggleFollowUseCase = toggleFollowUseCase
        self.postRepository = postRepository
    }

    // MARK: - Actions

    func loadProfile() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let profile = try await fetchProfileUseCase.execute(
                FetchProfileInput(userId: userId)
            )
            user = profile

            let userPosts = try await postRepository.fetchUserPosts(
                userId: profile.id,
                page: 1,
                perPage: 30
            )
            posts = userPosts
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleFollow() async {
        guard var currentUser = user, !isCurrentUser else { return }

        // Optimistic update
        let wasFollowing = currentUser.isFollowing
        currentUser.isFollowing = !wasFollowing
        user = currentUser

        do {
            try await toggleFollowUseCase.execute(
                ToggleFollowInput(userId: currentUser.id, isCurrentlyFollowing: wasFollowing)
            )
        } catch {
            // Revert
            currentUser.isFollowing = wasFollowing
            user = currentUser
        }
    }
}
