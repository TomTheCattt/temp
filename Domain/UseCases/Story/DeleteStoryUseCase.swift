//
//  DeleteStoryUseCase.swift
//  Instagram
//
//  Created by Antigravity on 22/10/26.
//

import Foundation

// MARK: - DeleteStoryUseCaseProtocol

protocol DeleteStoryUseCaseProtocol: Sendable {
    func execute(storyId: String) async throws
}

// MARK: - DeleteStoryUseCase

final class DeleteStoryUseCase: DeleteStoryUseCaseProtocol, Sendable {

    private let storyRepository: StoryRepositoryProtocol

    init(storyRepository: StoryRepositoryProtocol) {
        self.storyRepository = storyRepository
    }

    func execute(storyId: String) async throws {
        try await storyRepository.deleteStory(id: storyId)
    }
}
