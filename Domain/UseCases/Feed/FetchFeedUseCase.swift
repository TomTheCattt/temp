//
//  FetchFeedUseCase.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - FetchFeedUseCase

protocol FetchFeedUseCaseProtocol: Sendable {
    func execute(_ input: PaginationInput) async throws -> [Post]
}

final class FetchFeedUseCase: FetchFeedUseCaseProtocol, Sendable {

    private let postRepository: PostRepositoryProtocol

    init(postRepository: PostRepositoryProtocol) {
        self.postRepository = postRepository
    }

    func execute(_ input: PaginationInput) async throws -> [Post] {
        try await postRepository.fetchFeed(page: input.page, perPage: input.perPage)
    }
}
