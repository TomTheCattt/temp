//
//  ToggleSavePostUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/9/26.
//

import Foundation

// MARK: - ToggleSaveInput

struct ToggleSaveInput: Sendable {
    let postId: String
    let isCurrentlySaved: Bool
}

// MARK: - ToggleSavePostUseCase

protocol ToggleSavePostUseCaseProtocol: Sendable {
    func execute(_ input: ToggleSaveInput) async throws
}

final class ToggleSavePostUseCase: ToggleSavePostUseCaseProtocol, Sendable {

    private let postRepository: PostRepositoryProtocol

    init(postRepository: PostRepositoryProtocol) {
        self.postRepository = postRepository
    }

    func execute(_ input: ToggleSaveInput) async throws {
        if input.isCurrentlySaved {
            try await postRepository.unsavePost(id: input.postId)
        } else {
            try await postRepository.savePost(id: input.postId)
        }
    }
}
