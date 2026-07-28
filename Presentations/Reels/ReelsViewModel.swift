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

    // MARK: - State

    private(set) var reels: [Reel] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// Currently visible reel index (for auto-play).
    var currentIndex: Int = 0

    private var currentPage = 1
    private var hasMorePages = true

    // MARK: - Dependencies

    private let fetchReelsUseCase: FetchReelsUseCaseProtocol
    private let toggleLikeReelUseCase: ToggleLikeReelUseCaseProtocol

    // MARK: - Init

    init(
        fetchReelsUseCase: FetchReelsUseCaseProtocol,
        toggleLikeReelUseCase: ToggleLikeReelUseCaseProtocol
    ) {
        self.fetchReelsUseCase = fetchReelsUseCase
        self.toggleLikeReelUseCase = toggleLikeReelUseCase
    }

    // MARK: - Actions

    func loadReels() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        currentPage = 1

        do {
            let result = try await fetchReelsUseCase.execute(PaginationInput(page: 1, perPage: 10))
            reels = result
            hasMorePages = result.count >= 10
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
            let result = try await fetchReelsUseCase.execute(PaginationInput(page: nextPage, perPage: 10))
            reels.append(contentsOf: result)
            currentPage = nextPage
            hasMorePages = result.count >= 10
        } catch {
            // Silent fail
        }

        isLoading = false
    }

    func toggleLike(for reel: Reel) async {
        guard let index = reels.firstIndex(where: { $0.id == reel.id }) else { return }

        // Optimistic update
        let newLiked = !reel.isLiked
        let newCount = reel.likesCount + (newLiked ? 1 : -1)
        reels[index] = Reel(
            id: reel.id,
            author: reel.author,
            videoURL: reel.videoURL,
            thumbnailURL: reel.thumbnailURL,
            caption: reel.caption,
            audioTrack: reel.audioTrack,
            likesCount: newCount,
            commentsCount: reel.commentsCount,
            sharesCount: reel.sharesCount,
            viewsCount: reel.viewsCount,
            duration: reel.duration,
            isLiked: newLiked,
            isSaved: reel.isSaved,
            createdAt: reel.createdAt
        )

        do {
            try await toggleLikeReelUseCase.execute(
                ToggleLikeReelInput(reelId: reel.id, isCurrentlyLiked: reel.isLiked)
            )
        } catch {
            // Revert
            reels[index] = reel
        }
    }

    func onReelAppear(at index: Int) {
        currentIndex = index

        // Prefetch more when near end
        if index >= reels.count - 3 {
            Task { await loadMore() }
        }
    }
}
