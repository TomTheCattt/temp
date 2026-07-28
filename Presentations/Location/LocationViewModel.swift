//
//  LocationViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - LocationViewModel

@MainActor
@Observable
final class LocationViewModel {

    // MARK: - State

    private(set) var posts: [Post] = []
    private(set) var isLoading = false

    let locationName: String

    private var currentPage = 1
    private var hasMorePages = true

    // MARK: - Dependencies

    private let postRepository: PostRepositoryProtocol

    // MARK: - Init

    init(locationName: String, postRepository: PostRepositoryProtocol) {
        self.locationName = locationName
        self.postRepository = postRepository
    }

    // MARK: - Actions

    func loadPosts() async {
        guard !isLoading else { return }
        isLoading = true
        currentPage = 1

        do {
            // Mock: use explore posts filtered/shuffled
            let result = try await postRepository.fetchExplorePosts(page: 1, perPage: 30)
            posts = result
            hasMorePages = result.count >= 30
        } catch {
            // Silent fail
        }

        isLoading = false
    }

    func loadMore() async {
        guard !isLoading, hasMorePages else { return }
        isLoading = true

        let nextPage = currentPage + 1
        do {
            let result = try await postRepository.fetchExplorePosts(page: nextPage, perPage: 30)
            posts.append(contentsOf: result)
            currentPage = nextPage
            hasMorePages = result.count >= 30
        } catch {
            // Silent fail
        }

        isLoading = false
    }
}
