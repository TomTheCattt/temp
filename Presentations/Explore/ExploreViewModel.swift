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

    var explorePosts: [Post] = []
    var searchResults: [User] = []
    var isLoading = false
    var isLoadingMore = false
    var isSearching = false
    var selectedCategory: String = "Dành cho bạn"
    var searchText = ""

    // MARK: - Filtered Explore Posts

    var filteredExplorePosts: [Post] {
        guard selectedCategory != "Dành cho bạn" else { return explorePosts }
        let keywords = categoryKeywords(for: selectedCategory)
        let filtered = explorePosts.filter { post in
            guard let caption = post.caption?.lowercased() else { return false }
            return keywords.contains { caption.contains($0) }
        }
        return filtered.isEmpty ? explorePosts : filtered
    }

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

    // MARK: - Actions

    func selectCategory(_ category: String) {
        selectedCategory = category
    }

    func loadExplore() async {
        // TODO: Implement loadExplore logic from scratch
    }

    func loadMoreExplore() async {
        // TODO: Implement loadMoreExplore logic from scratch
    }

    func search() {
        // TODO: Implement search logic from scratch
    }

    func clearSearch() {
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
