//
//  SearchResultsViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - SearchTab

enum SearchTab: String, CaseIterable {
    case top = "Top"
    case accounts = "Accounts"
    case tags = "Tags"
    case places = "Places"
}

// MARK: - SearchResultsViewModel

@MainActor
@Observable
final class SearchResultsViewModel {

    // MARK: - State

    private(set) var users: [User] = []
    private(set) var posts: [Post] = []
    private(set) var isLoading = false

    var selectedTab: SearchTab = .top
    let query: String

    // MARK: - Dependencies

    private let searchUsersUseCase: SearchUsersUseCaseProtocol
    private let postRepository: PostRepositoryProtocol

    // MARK: - Init

    init(
        query: String,
        searchUsersUseCase: SearchUsersUseCaseProtocol,
        postRepository: PostRepositoryProtocol
    ) {
        self.query = query
        self.searchUsersUseCase = searchUsersUseCase
        self.postRepository = postRepository
    }

    // MARK: - Actions

    func loadResults() async {
        guard !isLoading else { return }
        isLoading = true

        async let usersResult = searchUsersUseCase.execute(
            SearchInput(query: query, page: 1)
        )
        async let postsResult = postRepository.fetchExplorePosts(page: 1, perPage: 20)

        do {
            users = try await usersResult
        } catch {
            users = []
        }

        do {
            posts = try await postsResult
        } catch {
            posts = []
        }

        isLoading = false
    }
}
