//
//  SearchResultsViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - SearchTab

enum SearchTab: String, CaseIterable, Sendable {
    case top = "Top"
    case accounts = "Accounts"
    case tags = "Tags"
    case places = "Places"
}

// MARK: - SearchTagItem

struct SearchTagItem: Identifiable, Hashable, Sendable {
    var id: String { name }
    let name: String
    let postCount: Int
}

// MARK: - SearchPlaceItem

struct SearchPlaceItem: Identifiable, Hashable, Sendable {
    var id: String { name }
    let name: String
    let subtitle: String
}

// MARK: - SearchResultsViewModel

@MainActor
@Observable
final class SearchResultsViewModel {

    // MARK: - State

    var users: [User] = []
    var posts: [Post] = []
    var tags: [SearchTagItem] = []
    var places: [SearchPlaceItem] = []
    var isLoading = false

    var selectedTab: SearchTab = .top
    var query: String

    // MARK: - Dependencies

    private let searchUsersUseCase: SearchUsersUseCaseProtocol

    // MARK: - Init

    init(
        query: String,
        searchUsersUseCase: SearchUsersUseCaseProtocol
    ) {
        self.query = query
        self.searchUsersUseCase = searchUsersUseCase
    }

    // MARK: - Actions

    func loadResults() async {
        // TODO: Implement loadResults for search from scratch
    }

    func updateQuery(_ newQuery: String) {
        query = newQuery
        Task { await loadResults() }
    }
}
