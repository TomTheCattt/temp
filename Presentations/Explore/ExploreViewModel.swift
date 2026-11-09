//
//  ExploreViewModel.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Combine
import CombineExt
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
    var searchText = "" {
        didSet {
            if searchText.isEmpty {
                searchResults = []
                isSearching = false
            } else if searchText.count >= 2 {
                isSearching = true
            }
            searchSubject.send(searchText)
        }
    }

    // Cursor-based pagination
    private var nextCursor: String?
    private var hasMore = true

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
    private let searchSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        postRepository: PostRepositoryProtocol,
        searchUsersUseCase: SearchUsersUseCaseProtocol
    ) {
        self.postRepository = postRepository
        self.searchUsersUseCase = searchUsersUseCase
        setupSearchPipeline()
    }

    // MARK: - Search Pipeline (CombineExt)

    private func setupSearchPipeline() {
        searchSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .flatMapLatest { [weak self] (query: String) -> AnyPublisher<[User], Never> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.count >= 2 else {
                    return Just([]).eraseToAnyPublisher()
                }
                let useCase = self.searchUsersUseCase
                return Deferred {
                    Future<[User], Never> { promise in
                        Task {
                            do {
                                let results = try await useCase.execute(SearchInput(query: trimmed))
                                promise(.success(results))
                            } catch {
                                promise(.success([]))
                            }
                        }
                    }
                }
                .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] users in
                guard let self else { return }
                self.searchResults = users
                self.isSearching = false
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func selectCategory(_ category: String) {
        selectedCategory = category
    }

    func loadExplore() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await postRepository.fetchExplorePosts(cursor: nil, perPage: 24)
            explorePosts = result.posts
            nextCursor = result.nextCursor
            hasMore = result.hasMore
        } catch {
            AppLogger.general.error("Failed to load explore posts: \(error.localizedDescription)")
        }
    }

    func loadMoreExplore() async {
        guard !isLoadingMore, !isLoading, hasMore, let cursor = nextCursor else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let result = try await postRepository.fetchExplorePosts(cursor: cursor, perPage: 24)
            explorePosts.append(contentsOf: result.posts)
            nextCursor = result.nextCursor
            hasMore = result.hasMore
        } catch {
            AppLogger.general.error("Failed to load more explore posts: \(error.localizedDescription)")
        }
    }

    func search() {
        searchSubject.send(searchText)
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
