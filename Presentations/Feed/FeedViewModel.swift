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
    private(set) var isRefreshing = false
    private(set) var errorMessage: String?

    private var currentPage = 1
    private var hasMorePages = true

    // MARK: - Dependencies

    private let fetchFeedUseCase: FetchFeedUseCaseProtocol
    private let toggleLikeUseCase: ToggleLikePostUseCaseProtocol

    // MARK: - Init

    init(
        fetchFeedUseCase: FetchFeedUseCaseProtocol,
        toggleLikeUseCase: ToggleLikePostUseCaseProtocol
    ) {
        self.fetchFeedUseCase = fetchFeedUseCase
        self.toggleLikeUseCase = toggleLikeUseCase
    }

    // MARK: - Actions

    func loadFeed() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        currentPage = 1

        do {
            let result = try await fetchFeedUseCase.execute(PaginationInput(page: 1))
            posts = result
            hasMorePages = result.count >= 20
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        isRefreshing = true
        currentPage = 1

        do {
            let result = try await fetchFeedUseCase.execute(PaginationInput(page: 1))
            posts = result
            hasMorePages = result.count >= 20
        } catch {
            errorMessage = error.localizedDescription
        }

        isRefreshing = false
    }

    func loadMore() async {
        guard !isLoading, hasMorePages else { return }
        isLoading = true

        let nextPage = currentPage + 1
        do {
            let result = try await fetchFeedUseCase.execute(PaginationInput(page: nextPage))
            posts.append(contentsOf: result)
            currentPage = nextPage
            hasMorePages = result.count >= 20
        } catch {
            // Silent fail for pagination
        }

        isLoading = false
    }

    func toggleLike(for post: Post) async {
        // Optimistic update
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            let current = posts[index]
            let newLiked = !current.isLiked
            let newCount = current.likesCount + (newLiked ? 1 : -1)
            posts[index] = Post(
                id: current.id,
                author: current.author,
                caption: current.caption,
                mediaItems: current.mediaItems,
                location: current.location,
                likesCount: newCount,
                commentsCount: current.commentsCount,
                createdAt: current.createdAt,
                isLiked: newLiked,
                isSaved: current.isSaved,
                isSponsored: current.isSponsored
            )
        }

        do {
            try await toggleLikeUseCase.execute(
                ToggleLikeInput(postId: post.id, isCurrentlyLiked: post.isLiked)
            )
        } catch {
            // Revert on failure
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index] = post
            }
        }
    }
}
