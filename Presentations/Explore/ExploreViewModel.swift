//
//  ExploreViewModel.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - ExploreViewModel

@MainActor
@Observable
final class ExploreViewModel {

    // MARK: - State

    private(set) var explorePosts: [Post] = []
    private(set) var searchResults: [User] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var isSearching = false
    private(set) var selectedCategory: String = "Dành cho bạn"

    var searchText = "" {
        didSet {
            search()
        }
    }

    private var currentPage = 1
    private var hasMorePages = true
    private var searchTask: Task<Void, Never>?

    // MARK: - Dependencies

    private let postRepository: PostRepositoryProtocol
    private let searchUsersUseCase: SearchUsersUseCaseProtocol

    // MARK: - Init

    init(
        postRepository: PostRepositoryProtocol,
        searchUsersUseCase: SearchUsersUseCaseProtocol
    ) {
        self.postRepository = postRepository
        self.searchUsersUseCase = searchUsersUseCase
    }

    // MARK: - Computed Properties

    var filteredExplorePosts: [Post] {
        guard selectedCategory != "Dành cho bạn" else { return explorePosts }
        let keywords = categoryKeywords(for: selectedCategory)
        let filtered = explorePosts.filter { post in
            guard let caption = post.caption?.lowercased() else { return false }
            return keywords.contains { caption.contains($0) }
        }
        return filtered.isEmpty ? explorePosts : filtered
    }

    // MARK: - Actions

    func selectCategory(_ category: String) {
        selectedCategory = category
    }

    func loadExplore() async {
        guard !isLoading else { return }
        isLoading = true
        currentPage = 1

        do {
            explorePosts = try await postRepository.fetchExplorePosts(page: 1, perPage: 30)
            hasMorePages = explorePosts.count >= 20
        } catch {
            // Keep existing posts if any
        }

        isLoading = false
    }

    func loadMoreExplore() async {
        guard !isLoading, !isLoadingMore, hasMorePages else { return }
        isLoadingMore = true
        let nextPage = currentPage + 1

        do {
            let newPosts = try await postRepository.fetchExplorePosts(page: nextPage, perPage: 20)
            if newPosts.isEmpty {
                hasMorePages = false
            } else {
                explorePosts.append(contentsOf: newPosts)
                currentPage = nextPage
            }
        } catch {
            // Transient failure
        }

        isLoadingMore = false
    }

    func search() {
        searchTask?.cancel()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard query.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            do {
                // 300ms debounce
                try await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }

                let results = try await searchUsersUseCase.execute(
                    SearchInput(query: query)
                )
                guard !Task.isCancelled else { return }
                searchResults = results
            } catch {
                guard !Task.isCancelled else { return }
                searchResults = []
            }
            isSearching = false
        }
    }

    func clearSearch() {
        searchTask?.cancel()
        searchText = ""
        searchResults = []
        isSearching = false
    }

    // MARK: - Helpers

    private func categoryKeywords(for category: String) -> [String] {
        switch category {
        case "Nhiếp ảnh": return ["photo", "shot", "camera", "nature"]
        case "Du lịch":   return ["travel", "places", "exploring", "visit"]
        case "Thời trang": return ["fashion", "style", "outfit", "design"]
        case "Ẩm thực":   return ["food", "coffee", "cooking", "recipe", "delicious"]
        case "Âm nhạc":   return ["music", "song", "vibes", "trend", "dance"]
        case "Thể thao":  return ["sport", "fitness", "run", "workout"]
        case "Kiến trúc": return ["architecture", "building", "design"]
        case "Công nghệ": return ["developer", "code", "tech", "bug", "life"]
        case "Nghệ thuật": return ["art", "artist", "design", "creative"]
        default:          return []
        }
    }
}
