//
//  SavedPostsViewModel.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import Foundation
import Observation

// MARK: - SavedPostsViewModel

@MainActor
@Observable
final class SavedPostsViewModel {

    private(set) var posts: [Post] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let fetchSavedPostsUseCase: FetchSavedPostsUseCaseProtocol
    private var didLoad = false
    private var nextCursor: String?
    private var hasMore = true

    init(fetchSavedPostsUseCase: FetchSavedPostsUseCaseProtocol) {
        self.fetchSavedPostsUseCase = fetchSavedPostsUseCase
    }

    func loadSavedPosts(reset: Bool = false) async {
        guard !isLoading else { return }
        if didLoad && !reset { return }

        isLoading = true
        errorMessage = nil

        do {
            let cursor = reset ? nil : nextCursor
            let result = try await fetchSavedPostsUseCase.execute(cursor: cursor, perPage: 30)

            if reset {
                posts = result.posts
            } else {
                posts.append(contentsOf: result.posts)
            }

            nextCursor = result.nextCursor
            hasMore = result.hasMore
            didLoad = true
        } catch {
            errorMessage = error.userMessage
        }

        isLoading = false
    }
}
