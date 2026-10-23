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

    // MARK: - Actions

    func loadReels() async {
        // TODO: Implement loadReels logic from scratch
    }

    func setFeedMode(_ mode: FeedMode) {
        feedMode = mode
        // TODO: Implement setFeedMode filtering logic from scratch
    }

    func loadMore() async {
        // TODO: Implement loadMore reels logic from scratch
    }

    func onCurrentReelChanged(to id: String?) {
        currentReelId = id
        // TODO: Implement onCurrentReelChanged prefetch and video buffering logic from scratch
    }

    func toggleLike(for reel: Reel) async {
        _ = reel
        // TODO: Implement toggleLike logic from scratch
    }

    func toggleSave(for reel: Reel) async {
        _ = reel
        // TODO: Implement toggleSave logic from scratch
    }

    func followAuthor(of reel: Reel) async {
        _ = reel
        // TODO: Implement followAuthor logic from scratch
    }
}
