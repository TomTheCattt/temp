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
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let input = FetchProfileInput(userId: userId)
            let user = try await fetchProfileUseCase.execute(input)
            self.user = user

            // Load posts for the profile grid
            let postsResult = try await postRepository.fetchUserPosts(userId: user.id, cursor: nil, perPage: 24)
            self.posts = postsResult.posts

        } catch {
            errorMessage = error.localizedDescription
            AppLogger.general.error("Failed to load profile: \(error.localizedDescription)")
        }
    }

    func loadReelsIfNeeded() async {
        guard !isLoadingReels, reels.isEmpty, let user = user else { return }
        isLoadingReels = true
        defer { isLoadingReels = false }

        do {
            let result = try await reelRepository.fetchUserReels(userId: user.id, cursor: nil, perPage: 24)
            self.reels = result.reels
        } catch {
            AppLogger.general.error("Failed to load reels: \(error.localizedDescription)")
        }
    }

    func toggleFollow() async {
        guard let user = user else { return }
        let wasFollowing = user.isFollowing

        do {
            // Use ToggleFollowInput with correct parameters
            let input = ToggleFollowInput(userId: user.id, isCurrentlyFollowing: wasFollowing)
            try await toggleFollowUseCase.execute(input)

            // Update local state optimistically by reconstructing User
            var updatedUser = user
            updatedUser.isFollowing = !wasFollowing
            // Since followersCount is immutable, we reconstruct the user with updated count
            let newFollowersCount = user.followersCount + (wasFollowing ? -1 : 1)
            updatedUser = User(
                id: user.id,
                username: user.username,
                fullName: user.fullName,
                email: user.email,
                phone: user.phone,
                avatarURL: user.avatarURL,
                bio: user.bio,
                website: user.website,
                isVerified: user.isVerified,
                isPrivate: user.isPrivate,
                followersCount: newFollowersCount,
                followingCount: user.followingCount,
                postsCount: user.postsCount,
                createdAt: user.createdAt,
                isFollowing: !wasFollowing,
                isFollowedBy: user.isFollowedBy,
                isBlocked: user.isBlocked
            )
            self.user = updatedUser

            // Also update SessionStore if this is the current user
            if isCurrentUser {
                SessionStore.shared.setSession(user: updatedUser)
            }
        } catch {
            AppLogger.general.error("Failed to toggle follow: \(error.localizedDescription)")
        }
    }

    func applyUpdatedUser(_ updatedUser: User) {
        // Only update if it's the same user
        if user?.id == updatedUser.id {
            self.user = updatedUser
            if isCurrentUser {
                SessionStore.shared.setSession(user: updatedUser)
            }
        }
    }
}
