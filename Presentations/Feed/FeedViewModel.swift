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
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await fetchFeedUseCase.execute(PaginationInput(cursor: nil, perPage: 20))
            posts = result.posts
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.general.error("Failed to load feed: \(error.localizedDescription)")
        }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil
        defer { isRefreshing = false }

        do {
            let result = try await fetchFeedUseCase.execute(PaginationInput(cursor: nil, perPage: 20))
            posts = result.posts
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.general.error("Failed to refresh feed: \(error.localizedDescription)")
        }
    }

    func loadMore() async {
        guard !isLoadingMore, !isLoading, !posts.isEmpty else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            // Use the last post's createdAt as cursor for cursor-based pagination
            let cursor = posts.last?.createdAt.iso8601String
            let result = try await fetchFeedUseCase.execute(PaginationInput(cursor: cursor, perPage: 20))
            posts.append(contentsOf: result.posts)
        } catch {
            AppLogger.general.error("Failed to load more feed: \(error.localizedDescription)")
        }
    }

    func toggleLike(for post: Post) async {
        do {
            let newLikeState = !post.isLiked
            try await toggleLikeUseCase.execute(ToggleLikeInput(postId: post.id, isCurrentlyLiked: post.isLiked))
            // Update local state optimistically using helper method
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index] = posts[index].withLike(newLikeState)
            }
        } catch {
            AppLogger.general.error("Failed to toggle like: \(error.localizedDescription)")
        }
    }

    func toggleSave(for post: Post) async {
        do {
            let newSaveState = !post.isSaved
            try await toggleSaveUseCase.execute(ToggleSaveInput(postId: post.id, isCurrentlySaved: post.isSaved))
            // Update local state optimistically using helper method
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index] = posts[index].withSaved(newSaveState)
            }
        } catch {
            AppLogger.general.error("Failed to toggle save: \(error.localizedDescription)")
        }
    }

    func refreshUnreadNotificationCount() async {
        do {
            let count = try await fetchUnreadNotificationCountUseCase.execute()
            AppState.shared.setUnreadNotificationCount(count)
        } catch {
            AppLogger.general.error("Failed to fetch unread notification count: \(error.localizedDescription)")
        }
    }

    // MARK: - Post Creation Sync

    func handleNewPost(_ post: Post) {
        // Insert new post at the top of the feed
        posts.insert(post, at: 0)
    }
}
