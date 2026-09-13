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

    private(set) var posts: [Post] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var isRefreshing = false
    private(set) var errorMessage: String?

    private let perPage = 20
    private var currentPage = 1
    private var hasMorePages = true

    // MARK: - Dependencies

    private let fetchFeedUseCase: FetchFeedUseCaseProtocol
    private let toggleLikeUseCase: ToggleLikePostUseCaseProtocol
    private let toggleSaveUseCase: ToggleSavePostUseCaseProtocol

    // MARK: - Init

    init(
        fetchFeedUseCase: FetchFeedUseCaseProtocol,
        toggleLikeUseCase: ToggleLikePostUseCaseProtocol,
        toggleSaveUseCase: ToggleSavePostUseCaseProtocol
    ) {
        self.fetchFeedUseCase = fetchFeedUseCase
        self.toggleLikeUseCase = toggleLikeUseCase
        self.toggleSaveUseCase = toggleSaveUseCase
    }

    // MARK: - Actions

    func loadFeed() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        currentPage = 1

        do {
            let result = try await fetchFeedUseCase.execute(PaginationInput(page: 1, perPage: perPage))
            posts = result
            hasMorePages = result.count >= perPage
        } catch {
            errorMessage = error.userMessage
        }

        isLoading = false
    }

    func refresh() async {
        isRefreshing = true
        errorMessage = nil
        currentPage = 1

        do {
            let result = try await fetchFeedUseCase.execute(PaginationInput(page: 1, perPage: perPage))
            posts = result
            hasMorePages = result.count >= perPage
        } catch {
            // Refresh failure with existing content: surface via toast, keep current posts.
            if posts.isEmpty {
                errorMessage = error.userMessage
            } else {
                ToastManager.shared.error(error.userMessage)
            }
        }

        isRefreshing = false
    }

    func loadMore() async {
        guard !isLoading, !isLoadingMore, !isRefreshing, hasMorePages else { return }
        isLoadingMore = true

        let nextPage = currentPage + 1
        do {
            let result = try await fetchFeedUseCase.execute(PaginationInput(page: nextPage, perPage: perPage))
            posts.append(contentsOf: result)
            currentPage = nextPage
            hasMorePages = result.count >= perPage
        } catch {
            // Silent fail for pagination — user can trigger loadMore again by scrolling.
        }

        isLoadingMore = false
    }

    func toggleLike(for post: Post) async {
        // Optimistic update
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            let current = posts[index]
            posts[index] = current.withLike(!current.isLiked)
        }

        do {
            try await toggleLikeUseCase.execute(
                ToggleLikeInput(postId: post.id, isCurrentlyLiked: post.isLiked)
            )
        } catch {
            // Revert on failure and notify via a lightweight toast.
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index] = post
            }
            ToastManager.shared.error(error.userMessage)
        }
    }

    func toggleSave(for post: Post) async {
        // Optimistic update
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            let current = posts[index]
            posts[index] = current.withSaved(!current.isSaved)
        }

        do {
            try await toggleSaveUseCase.execute(
                ToggleSaveInput(postId: post.id, isCurrentlySaved: post.isSaved)
            )
        } catch {
            // Revert on failure and notify via a lightweight toast.
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index] = post
            }
            ToastManager.shared.error(error.userMessage)
        }
    }
}
