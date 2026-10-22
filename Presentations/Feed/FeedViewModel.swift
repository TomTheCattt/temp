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

    /// Post ids with a like/save mutation currently in flight — prevents
    /// overlapping toggles from producing inconsistent counts.
    private var pendingLikeIds: Set<String> = []
    private var pendingSaveIds: Set<String> = []

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
        currentPage = 1

        async let feedTask = fetchFeedUseCase.execute(PaginationInput(page: 1, perPage: perPage))
        async let unreadTask: () = refreshUnreadNotificationCount()

        do {
            let (result, _) = try await (feedTask, unreadTask)
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

        async let feedTask = fetchFeedUseCase.execute(PaginationInput(page: 1, perPage: perPage))
        async let unreadTask: () = refreshUnreadNotificationCount()

        do {
            let (result, _) = try await (feedTask, unreadTask)
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

    func refreshUnreadNotificationCount() async {
        do {
            let count = try await fetchUnreadNotificationCountUseCase.execute()
            AppState.shared.setUnreadNotificationCount(count)
        } catch {
            // Non-blocking silent fail
        }
    }

    func loadMore() async {
        guard !isLoading, !isLoadingMore, !isRefreshing, hasMorePages else { return }
        isLoadingMore = true

        let nextPage = currentPage + 1
        do {
            let result = try await fetchFeedUseCase.execute(PaginationInput(page: nextPage, perPage: perPage))
            // Merge only posts we don't already have (guards against page-boundary
            // overlaps / duplicate ids that would break ForEach diffing).
            let existingIds = Set(posts.map(\.id))
            let newPosts = result.filter { !existingIds.contains($0.id) }
            posts.append(contentsOf: newPosts)
            currentPage = nextPage
            hasMorePages = result.count >= perPage
        } catch {
            // Silent fail for pagination — user can trigger loadMore again by scrolling.
        }

        isLoadingMore = false
    }

    func toggleLike(for post: Post) async {
        // Ignore overlapping toggles for the same post.
        guard !pendingLikeIds.contains(post.id) else { return }
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }

        pendingLikeIds.insert(post.id)
        defer { pendingLikeIds.remove(post.id) }

        // Read the CURRENT state (not the captured `post`, which may be stale).
        let current = posts[index]
        posts[index] = current.withLike(!current.isLiked)

        do {
            try await toggleLikeUseCase.execute(
                ToggleLikeInput(postId: current.id, isCurrentlyLiked: current.isLiked)
            )
        } catch {
            // Revert to the pre-toggle state and notify via a lightweight toast.
            if let revertIndex = posts.firstIndex(where: { $0.id == current.id }) {
                posts[revertIndex] = current
            }
            ToastManager.shared.error(error.userMessage)
        }
    }

    func toggleSave(for post: Post) async {
        // Ignore overlapping toggles for the same post.
        guard !pendingSaveIds.contains(post.id) else { return }
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }

        pendingSaveIds.insert(post.id)
        defer { pendingSaveIds.remove(post.id) }

        // Read the CURRENT state (not the captured `post`, which may be stale).
        let current = posts[index]
        posts[index] = current.withSaved(!current.isSaved)

        do {
            try await toggleSaveUseCase.execute(
                ToggleSaveInput(postId: current.id, isCurrentlySaved: current.isSaved)
            )
        } catch {
            // Revert to the pre-toggle state and notify via a lightweight toast.
            if let revertIndex = posts.firstIndex(where: { $0.id == current.id }) {
                posts[revertIndex] = current
            }
            ToastManager.shared.error(error.userMessage)
        }
    }

    // MARK: - Post Creation Sync

    func handleNewPost(_ post: Post) {
        guard !posts.contains(where: { $0.id == post.id }) else { return }
        posts.insert(post, at: 0)
    }
}
