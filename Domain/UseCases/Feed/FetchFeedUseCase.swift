//
//  FetchFeedUseCase.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - FetchFeedUseCase

protocol FetchFeedUseCaseProtocol: Sendable {
    func execute(_ input: PaginationInput) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool)
}

final class FetchFeedUseCase: FetchFeedUseCaseProtocol, Sendable {

    private let postRepository: PostRepositoryProtocol

    init(postRepository: PostRepositoryProtocol) {
        self.postRepository = postRepository
    }

    func execute(_ input: PaginationInput) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool) {
        try await postRepository.fetchFeed(cursor: input.cursor, perPage: input.perPage)
    }
}
