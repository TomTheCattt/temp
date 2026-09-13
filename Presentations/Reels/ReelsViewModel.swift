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

    // MARK: - Feed Mode

    enum FeedMode: Int {
        case forYou   // "Reels" tab — all reels
        case following // "Following" tab — reels from followed authors only
    }

    /// The full set fetched from the feed API (unfiltered).
    private var allReels: [Reel] = []

    /// The reels shown for the current `feedMode`.
    private(set) var reels: [Reel] = []
    private(set) var feedMode: FeedMode = .forYou
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var errorMessage: String?

    /// The id of the reel currently centered on screen, driven by scroll position.
    /// Optional so the ScrollView paging binding can be `nil` before first layout.
    var currentReelId: String?

    /// Index of the currently visible reel, derived from `currentReelId`.
    var currentIndex: Int {
        guard let currentReelId,
              let index = reels.firstIndex(where: { $0.id == currentReelId }) else {
            return 0
        }
        return index
    }

    private var currentPage = 1
    private var hasMorePages = true
    private let pageSize = 10
    private let prefetchThreshold = 3

    // MARK: - Dependencies

    private let fetchReelsUseCase: FetchReelsUseCaseProtocol
    private let toggleLikeReelUseCase: ToggleLikeReelUseCaseProtocol
    private let toggleFollowUseCase: ToggleFollowUseCaseProtocol
    private let reelRepository: ReelRepositoryProtocol

    // MARK: - Init

    init(
        fetchReelsUseCase: FetchReelsUseCaseProtocol,
        toggleLikeReelUseCase: ToggleLikeReelUseCaseProtocol,
        toggleFollowUseCase: ToggleFollowUseCaseProtocol,
        reelRepository: ReelRepositoryProtocol
    ) {
        self.fetchReelsUseCase = fetchReelsUseCase
        self.toggleLikeReelUseCase = toggleLikeReelUseCase
        self.toggleFollowUseCase = toggleFollowUseCase
        self.reelRepository = reelRepository
    }

    // MARK: - Loading

    func loadReels() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        currentPage = 1

        do {
            let result = try await fetchReelsUseCase.execute(PaginationInput(page: 1, perPage: pageSize))
            allReels = result
            hasMorePages = result.count >= pageSize
            applyFeedFilter(resetActive: true)
        } catch {
            errorMessage = error.userMessage
        }

        isLoading = false
    }

    /// Switches between the "Reels" (for you) and "Following" tabs.
    func setFeedMode(_ mode: FeedMode) {
        guard mode != feedMode else { return }
        feedMode = mode
        applyFeedFilter(resetActive: true)
    }

    /// Recomputes `reels` from `allReels` based on the current feed mode,
    /// and reseeds the active reel to the first visible item.
    private func applyFeedFilter(resetActive: Bool) {
        switch feedMode {
        case .forYou:
            reels = allReels
        case .following:
            reels = allReels.filter { $0.author.isFollowing }
        }

        if resetActive || currentReelId == nil || !reels.contains(where: { $0.id == currentReelId }) {
            currentReelId = reels.first?.id
        }
    }

    func loadMore() async {
        // Uses its own flag so it never blocks or masks an initial load / refresh.
        guard !isLoadingMore, !isLoading, hasMorePages else { return }
        isLoadingMore = true

        let nextPage = currentPage + 1
        do {
            let result = try await fetchReelsUseCase.execute(PaginationInput(page: nextPage, perPage: pageSize))
            allReels.append(contentsOf: result)
            currentPage = nextPage
            hasMorePages = result.count >= pageSize
            applyFeedFilter(resetActive: false)
        } catch {
            // Silent fail — pagination errors shouldn't disrupt the current reel.
        }

        isLoadingMore = false
    }

    // MARK: - Scroll / Active Reel

    /// Called when the centered reel changes (driven by `.scrollPosition`).
    func onCurrentReelChanged(to id: String?) {
        currentReelId = id
        guard let index = reels.firstIndex(where: { $0.id == id }) else { return }

        // Prefetch more when near the end.
        if index >= reels.count - prefetchThreshold {
            Task { await loadMore() }
        }

        // Preload the next reel's video for a smoother swipe.
        preloadAdjacentReels(currentIndex: index)
    }

    // MARK: - Interactions

    func toggleLike(for reel: Reel) async {
        guard let index = allReels.firstIndex(where: { $0.id == reel.id }) else { return }
        let original = allReels[index]

        // Optimistic update.
        updateReel(id: reel.id) { $0.togglingLike() }

        do {
            try await toggleLikeReelUseCase.execute(
                ToggleLikeReelInput(reelId: reel.id, isCurrentlyLiked: original.isLiked)
            )
        } catch {
            // Revert and notify.
            replaceReel(id: reel.id, with: original)
            ToastManager.shared.error(error.userMessage)
        }
    }

    func toggleSave(for reel: Reel) async {
        guard let index = allReels.firstIndex(where: { $0.id == reel.id }) else { return }
        let original = allReels[index]
        let willSave = !original.isSaved

        // Optimistic update.
        updateReel(id: reel.id) { $0.togglingSave() }

        do {
            if willSave {
                try await reelRepository.saveReel(id: reel.id)
            } else {
                try await reelRepository.unsaveReel(id: reel.id)
            }
        } catch {
            replaceReel(id: reel.id, with: original)
            ToastManager.shared.error(error.userMessage)
        }
    }

    /// Follows the author of the given reel. Optimistic; the Follow button hides on success.
    /// Reel feed authors are assumed not-yet-followed (no relationship state from the feed API).
    func followAuthor(of reel: Reel) async {
        let authorId = reel.author.id
        guard authorId != SessionStore.shared.currentUserId else { return }

        // Mark all reels by this author as followed so the button hides everywhere.
        setFollowing(true, forAuthor: authorId)

        do {
            try await toggleFollowUseCase.execute(
                ToggleFollowInput(userId: authorId, isCurrentlyFollowing: false)
            )
        } catch {
            setFollowing(false, forAuthor: authorId)
            ToastManager.shared.error(error.userMessage)
        }
    }

    // MARK: - Reel Mutation Helpers

    /// Applies a transform to a reel in the source list and re-derives the visible list.
    private func updateReel(id: String, _ transform: (Reel) -> Reel) {
        guard let index = allReels.firstIndex(where: { $0.id == id }) else { return }
        allReels[index] = transform(allReels[index])
        applyFeedFilter(resetActive: false)
    }

    private func replaceReel(id: String, with reel: Reel) {
        guard let index = allReels.firstIndex(where: { $0.id == id }) else { return }
        allReels[index] = reel
        applyFeedFilter(resetActive: false)
    }

    private func setFollowing(_ isFollowing: Bool, forAuthor authorId: String) {
        for i in allReels.indices where allReels[i].author.id == authorId {
            var author = allReels[i].author
            author.isFollowing = isFollowing
            allReels[i] = allReels[i].withAuthor(author)
        }
        applyFeedFilter(resetActive: false)
    }

    // MARK: - Preloading

    /// Preloads the next reel's video item for instant playback when the user swipes.
    private func preloadAdjacentReels(currentIndex: Int) {
        let nextIndex = currentIndex + 1
        guard reels.indices.contains(nextIndex) else { return }
        let nextReel = reels[nextIndex]
        VideoPlayerManager.shared.preload(url: nextReel.videoURL, for: nextReel.id)
    }
}
