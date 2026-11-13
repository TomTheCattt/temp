//
//  FetchUserPostsUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - FetchUserPostsUseCase

protocol FetchUserPostsUseCaseProtocol: Sendable {
    func execute(userId: String, cursor: String?, perPage: Int) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool)
}

final class FetchUserPostsUseCase: FetchUserPostsUseCaseProtocol, Sendable {

    private let postRepository: PostRepositoryProtocol

    init(postRepository: PostRepositoryProtocol) {
        self.postRepository = postRepository
    }

    func execute(userId: String, cursor: String? = nil, perPage: Int = 24) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool) {
        try await postRepository.fetchUserPosts(userId: userId, cursor: cursor, perPage: perPage)
    }
}
