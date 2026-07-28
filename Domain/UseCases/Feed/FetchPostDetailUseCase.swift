//
//  FetchPostDetailUseCase.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - FetchPostDetailInput

struct FetchPostDetailInput: Sendable {
    let postId: String
}

// MARK: - FetchPostDetailUseCase

protocol FetchPostDetailUseCaseProtocol: Sendable {
    func execute(_ input: FetchPostDetailInput) async throws -> Post
}

final class FetchPostDetailUseCase: FetchPostDetailUseCaseProtocol, Sendable {

    private let postRepository: PostRepositoryProtocol

    init(postRepository: PostRepositoryProtocol) {
        self.postRepository = postRepository
    }

    func execute(_ input: FetchPostDetailInput) async throws -> Post {
        try await postRepository.fetchPost(id: input.postId)
    }
}
