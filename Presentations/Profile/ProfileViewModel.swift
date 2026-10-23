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

    var user: User?
    var posts: [Post] = []
    var reels: [Reel] = []
    var isLoading = false
    var isLoadingReels = false
    var errorMessage: String?

    var isCurrentUser: Bool {
        let currentUserId = SessionStore.shared.currentUserId
        if userId == nil { return true }
        if let userId, !userId.isEmpty {
            if userId == currentUserId || userId == "user_current" { return true }
        }
        if let user, !user.id.isEmpty {
            if user.id == currentUserId || user.id == "user_current" { return true }
        }
        return false
    }

    private let userId: String?

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
        self.fetchProfileUseCase = fetchProfileUseCase
        self.toggleFollowUseCase = toggleFollowUseCase
        self.postRepository = postRepository
        self.reelRepository = reelRepository

        let currentUserId = SessionStore.shared.currentUserId
        let isMe = (userId == nil || userId == currentUserId)
        if isMe {
            self.user = SessionStore.shared.currentUser
        }
    }

    // MARK: - Actions

    func loadProfile() async {
        // TODO: Implement loadProfile logic from scratch
    }

    func loadReelsIfNeeded() async {
        // TODO: Implement loadReelsIfNeeded logic from scratch
    }

    func toggleFollow() async {
        // TODO: Implement toggleFollow logic from scratch
    }

    func applyUpdatedUser(_ updatedUser: User) {
        _ = updatedUser
        // TODO: Implement applyUpdatedUser logic from scratch
    }
}
