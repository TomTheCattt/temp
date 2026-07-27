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
    private(set) var isSearching = false

    var searchText = "" {
        didSet {
            if searchText.isEmpty {
                searchResults = []
                isSearching = false
            }
        }
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

    func loadExplore() async {
        guard !isLoading else { return }
        isLoading = true

        do {
            explorePosts = try await postRepository.fetchExplorePosts(page: 1, perPage: 30)
        } catch {
            // Silent fail for explore grid
        }

        isLoading = false
    }

    func search() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else {
            searchResults = []
            return
        }

        isSearching = true

        do {
            searchResults = try await searchUsersUseCase.execute(
                SearchInput(query: query)
            )
        } catch {
            searchResults = []
        }

        isSearching = false
    }
}
