//
//  FeedViewModel.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - FeedViewModel

@MainActor
@Observable
final class FeedViewModel {

    // MARK: - State

    var posts: [Post] = []
    var isLoading = false
    var isLoadingMore = false
    var isRefreshing = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let fetchFeedUseCase: FetchFeedUseCaseProtocol
    private let toggleLikeUseCase: ToggleLikePostUseCaseProtocol
    private let toggleSaveUseCase: ToggleSavePostUseCaseProtocol
    private let fetchUnreadNotificationCountUseCase: FetchUnreadNotificationCountUseCaseProtocol

    // MARK: - Init

    init(
        fetchFeedUseCase: FetchFeedUseCaseProtocol,
        toggleLikeUseCase: ToggleLikePostUseCaseProtocol,
        toggleSaveUseCase: ToggleSavePostUseCaseProtocol,
        fetchUnreadNotificationCountUseCase: FetchUnreadNotificationCountUseCaseProtocol
    ) {
        self.fetchFeedUseCase = fetchFeedUseCase
        self.toggleLikeUseCase = toggleLikeUseCase
        self.toggleSaveUseCase = toggleSaveUseCase
        self.fetchUnreadNotificationCountUseCase = fetchUnreadNotificationCountUseCase
    }

    // MARK: - Actions

    func loadFeed() async {
        // TODO: Implement loadFeed logic from scratch
    }

    func refresh() async {
        // TODO: Implement refresh logic from scratch
    }

    func refreshUnreadNotificationCount() async {
        // TODO: Implement refreshUnreadNotificationCount logic from scratch
    }

    func loadMore() async {
        // TODO: Implement pagination loadMore logic from scratch
    }

    func toggleLike(for post: Post) async {
        _ = post
        // TODO: Implement toggleLike logic from scratch
    }

    func toggleSave(for post: Post) async {
        _ = post
        // TODO: Implement toggleSave logic from scratch
    }

    // MARK: - Post Creation Sync

    func handleNewPost(_ post: Post) {
        _ = post
        // TODO: Implement handleNewPost sync logic from scratch
    }
}
