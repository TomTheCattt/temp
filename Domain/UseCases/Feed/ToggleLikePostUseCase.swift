//
//  ToggleLikePostUseCase.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - ToggleLikeInput

struct ToggleLikeInput: Sendable {
    let postId: String
    let isCurrentlyLiked: Bool
}

// MARK: - ToggleLikePostUseCase

protocol ToggleLikePostUseCaseProtocol: Sendable {
    func execute(_ input: ToggleLikeInput) async throws
}

final class ToggleLikePostUseCase: ToggleLikePostUseCaseProtocol, Sendable {

    private let postRepository: PostRepositoryProtocol

    init(postRepository: PostRepositoryProtocol) {
        self.postRepository = postRepository
    }

    func execute(_ input: ToggleLikeInput) async throws {
        if input.isCurrentlyLiked {
            try await postRepository.unlikePost(id: input.postId)
        } else {
            try await postRepository.likePost(id: input.postId)
        }
    }
}
