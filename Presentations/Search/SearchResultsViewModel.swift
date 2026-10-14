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

    private(set) var users: [User] = []
    private(set) var posts: [Post] = []
    private(set) var tags: [SearchTagItem] = []
    private(set) var places: [SearchPlaceItem] = []
    private(set) var isLoading = false

    var selectedTab: SearchTab = .top
    var query: String

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
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            users = []
            posts = []
            tags = []
            places = []
            return
        }

        isLoading = true

        async let usersResult = searchUsersUseCase.execute(
            SearchInput(query: trimmed, page: 1)
        )
        async let postsResult = postRepository.fetchExplorePosts(page: 1, perPage: 30)

        do {
            users = try await usersResult
        } catch {
            users = []
        }

        do {
            let fetchedPosts = try await postsResult
            let lowered = trimmed.lowercased()

            // Filter posts matching query in caption or location or author
            let matchingPosts = fetchedPosts.filter { post in
                (post.caption?.lowercased().contains(lowered) ?? false) ||
                (post.location?.name.lowercased().contains(lowered) ?? false) ||
                post.author.username.lowercased().contains(lowered) ||
                post.author.fullName.lowercased().contains(lowered)
            }
            posts = matchingPosts.isEmpty ? Array(fetchedPosts.prefix(12)) : matchingPosts

            // Generate deterministic tags based on query and post hashtags
            var extractedTags: Set<String> = []
            for post in fetchedPosts {
                if let caption = post.caption {
                    let words = caption.split(separator: " ")
                    for word in words where word.hasPrefix("#") {
                        let cleanTag = String(word.dropFirst()).lowercased()
                        if cleanTag.contains(lowered) {
                            extractedTags.insert(cleanTag)
                        }
                    }
                }
            }

            var tagList: [SearchTagItem] = []
            let cleanQuery = trimmed.replacingOccurrences(of: "#", with: "").lowercased()
            tagList.append(SearchTagItem(
                name: cleanQuery,
                postCount: abs(cleanQuery.hashValue % 45_000) + 1_500
            ))
            for tag in extractedTags.sorted() where tag != cleanQuery {
                tagList.append(SearchTagItem(
                    name: tag,
                    postCount: abs(tag.hashValue % 20_000) + 800
                ))
            }
            tags = tagList

            // Generate places matching query
            var placeList: [SearchPlaceItem] = []
            for post in fetchedPosts {
                if let loc = post.location, loc.name.lowercased().contains(lowered) {
                    if !placeList.contains(where: { $0.name == loc.name }) {
                        placeList.append(SearchPlaceItem(name: loc.name, subtitle: "Việt Nam"))
                    }
                }
            }
            if placeList.isEmpty {
                placeList.append(SearchPlaceItem(name: trimmed, subtitle: "Địa điểm • Việt Nam"))
                placeList.append(SearchPlaceItem(name: "\(trimmed) Center", subtitle: "Khu vực nổi bật"))
            }
            places = placeList
        } catch {
            posts = []
            tags = []
            places = []
        }

        isLoading = false
    }

    func updateQuery(_ newQuery: String) {
        query = newQuery
        Task {
            await loadResults()
        }
    }
}
