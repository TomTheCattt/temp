//
//  FetchExplorePostsUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - FetchExplorePostsUseCase

protocol FetchExplorePostsUseCaseProtocol: Sendable {
    func execute(cursor: String?, perPage: Int) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool)
}

final class FetchExplorePostsUseCase: FetchExplorePostsUseCaseProtocol, Sendable {

    private let postRepository: PostRepositoryProtocol

    init(postRepository: PostRepositoryProtocol) {
        self.postRepository = postRepository
    }

    func execute(cursor: String? = nil, perPage: Int = 24) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool) {
        try await postRepository.fetchExplorePosts(cursor: cursor, perPage: perPage)
    }
}
