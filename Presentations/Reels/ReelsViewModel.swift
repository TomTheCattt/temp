//
//  ReelsViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - ReelsViewModel

@MainActor
@Observable
final class ReelsViewModel {

    // MARK: - Feed Mode

    enum FeedMode: Int {
        case forYou
        case following
    }

    // MARK: - State

    var reels: [Reel] = []
    var feedMode: FeedMode = .forYou
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?
    var currentReelId: String?

    var currentIndex: Int {
        guard let currentReelId,
              let index = reels.firstIndex(where: { $0.id == currentReelId }) else {
            return 0
        }
        return index
    }

    // MARK: - Dependencies

    private let fetchReelsUseCase: FetchReelsUseCaseProtocol
    private let toggleLikeReelUseCase: ToggleLikeReelUseCaseProtocol
    private let toggleFollowUseCase: ToggleFollowUseCaseProtocol
    private let toggleSaveReelUseCase: ToggleSaveReelUseCaseProtocol

    // MARK: - Init

    init(
        fetchReelsUseCase: FetchReelsUseCaseProtocol,
        toggleLikeReelUseCase: ToggleLikeReelUseCaseProtocol,
        toggleFollowUseCase: ToggleFollowUseCaseProtocol,
        toggleSaveReelUseCase: ToggleSaveReelUseCaseProtocol
    ) {
        self.fetchReelsUseCase = fetchReelsUseCase
        self.toggleLikeReelUseCase = toggleLikeReelUseCase
        self.toggleFollowUseCase = toggleFollowUseCase
        self.toggleSaveReelUseCase = toggleSaveReelUseCase
    }

    // MARK: - Actions

    func loadReels() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await fetchReelsUseCase.execute(PaginationInput(cursor: nil, perPage: 20))
            reels = result.reels
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.general.error("Failed to load reels: \(error.localizedDescription)")
        }
    }

    func setFeedMode(_ mode: FeedMode) {
        feedMode = mode
        // Reload reels with new feed mode
        Task {
            await loadReels()
        }
    }

    func loadMore() async {
        guard !isLoadingMore, !isLoading, !reels.isEmpty else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            // Use the last reel's createdAt as cursor for cursor-based pagination
            let cursor = reels.last?.createdAt.iso8601String
            let result = try await fetchReelsUseCase.execute(PaginationInput(cursor: cursor, perPage: 20))
            reels.append(contentsOf: result.reels)
        } catch {
            AppLogger.general.error("Failed to load more reels: \(error.localizedDescription)")
        }
    }

    func onCurrentReelChanged(to id: String?) {
        currentReelId = id
        // Prefetch next reel if we're near the end
        if let id = id,
           let index = reels.firstIndex(where: { $0.id == id }),
           index >= reels.count - 3 {
            Task { await loadMore() }
        }
    }

    func toggleLike(for reel: Reel) async {
        do {
            try await toggleLikeReelUseCase.execute(ToggleLikeReelInput(reelId: reel.id, isCurrentlyLiked: reel.isLiked))
            // Update local state optimistically using helper method
            if let index = reels.firstIndex(where: { $0.id == reel.id }) {
                reels[index] = reels[index].togglingLike()
            }
        } catch {
            AppLogger.general.error("Failed to toggle reel like: \(error.localizedDescription)")
        }
    }

    func toggleSave(for reel: Reel) async {
        do {
            try await toggleSaveReelUseCase.execute(reelId: reel.id, shouldSave: !reel.isSaved)
            // Update local state optimistically using helper method
            if let index = reels.firstIndex(where: { $0.id == reel.id }) {
                reels[index] = reels[index].togglingSave()
            }
        } catch {
            AppLogger.general.error("Failed to toggle reel save: \(error.localizedDescription)")
        }
    }

    func followAuthor(of reel: Reel) async {
        do {
            let isFollowing = reel.author.isFollowing
            let input = ToggleFollowInput(userId: reel.author.id, isCurrentlyFollowing: isFollowing)
            try await toggleFollowUseCase.execute(input)
            // Update local state optimistically by updating the author
            if let index = reels.firstIndex(where: { $0.id == reel.id }) {
                var updatedAuthor = reel.author
                updatedAuthor.isFollowing = !isFollowing
                let newFollowersCount = reel.author.followersCount + (isFollowing ? -1 : 1)
                updatedAuthor = User(
                    id: reel.author.id,
                    username: reel.author.username,
                    fullName: reel.author.fullName,
                    email: reel.author.email,
                    phone: reel.author.phone,
                    avatarURL: reel.author.avatarURL,
                    bio: reel.author.bio,
                    website: reel.author.website,
                    isVerified: reel.author.isVerified,
                    isPrivate: reel.author.isPrivate,
                    followersCount: newFollowersCount,
                    followingCount: reel.author.followingCount,
                    postsCount: reel.author.postsCount,
                    createdAt: reel.author.createdAt,
                    isFollowing: !isFollowing,
                    isFollowedBy: reel.author.isFollowedBy,
                    isBlocked: reel.author.isBlocked
                )
                reels[index] = reels[index].withAuthor(updatedAuthor)
            }
        } catch {
            AppLogger.general.error("Failed to follow author: \(error.localizedDescription)")
        }
    }
}
