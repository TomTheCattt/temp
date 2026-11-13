//
//  FetchSavedPostsUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - FetchSavedPostsUseCase

protocol FetchSavedPostsUseCaseProtocol: Sendable {
    func execute(cursor: String?, perPage: Int) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool)
}

final class FetchSavedPostsUseCase: FetchSavedPostsUseCaseProtocol, Sendable {

    private let postRepository: PostRepositoryProtocol

    init(postRepository: PostRepositoryProtocol) {
        self.postRepository = postRepository
    }

    func execute(cursor: String? = nil, perPage: Int = 30) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool) {
        try await postRepository.fetchSavedPosts(cursor: cursor, perPage: perPage)
    }
}
