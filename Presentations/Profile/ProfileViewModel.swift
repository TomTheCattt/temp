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
    private(set) var reels: [Reel] = []
    private(set) var isLoading = false
    private(set) var isLoadingReels = false
    private(set) var errorMessage: String?

    let isCurrentUser: Bool
    private let userId: String?
    private var didLoadReels = false

    // MARK: - Dependencies

    private let fetchProfileUseCase: FetchProfileUseCaseProtocol
    private let toggleFollowUseCase: ToggleFollowUseCaseProtocol
    private let postRepository: PostRepositoryProtocol
    private let reelRepository: ReelRepositoryProtocol

    // MARK: - Init

    init(
        userId: String?,
        fetchProfileUseCase: FetchProfileUseCaseProtocol,
        toggleFollowUseCase: ToggleFollowUseCaseProtocol,
        postRepository: PostRepositoryProtocol,
        reelRepository: ReelRepositoryProtocol
    ) {
        self.userId = userId
        self.isCurrentUser = (userId == nil)
        self.fetchProfileUseCase = fetchProfileUseCase
        self.toggleFollowUseCase = toggleFollowUseCase
        self.postRepository = postRepository
        self.reelRepository = reelRepository
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
            errorMessage = error.userMessage
        }

        isLoading = false
    }

    /// Loads the user's reels lazily, the first time the Reels tab is opened.
    func loadReelsIfNeeded() async {
        guard !didLoadReels, !isLoadingReels else { return }
        guard let resolvedId = user?.id ?? userId else { return }

        isLoadingReels = true
        do {
            reels = try await reelRepository.fetchUserReels(
                userId: resolvedId,
                page: 1,
                perPage: 30
            )
            didLoadReels = true
        } catch {
            // Grid stays empty; a transient failure shouldn't block the whole profile.
            ToastManager.shared.error(error.userMessage)
        }
        isLoadingReels = false
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
            // Revert and notify.
            currentUser.isFollowing = wasFollowing
            user = currentUser
            ToastManager.shared.error(error.userMessage)
        }
    }

    /// Updates the displayed profile immediately when updated externally (e.g. from EditProfile).
    func applyUpdatedUser(_ updatedUser: User) {
        guard isCurrentUser || updatedUser.id == user?.id else { return }
        user = updatedUser
    }
}
