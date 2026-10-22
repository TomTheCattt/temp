//
//  MarkStoryViewedUseCase.swift
//  Instagram
//
//  Created by Antigravity on 22/10/26.
//

import Foundation

// MARK: - MarkStoryViewedUseCaseProtocol

protocol MarkStoryViewedUseCaseProtocol: Sendable {
    func execute(storyId: String) async throws
}

// MARK: - MarkStoryViewedUseCase

final class MarkStoryViewedUseCase: MarkStoryViewedUseCaseProtocol, Sendable {

    private let storyRepository: StoryRepositoryProtocol

    init(storyRepository: StoryRepositoryProtocol) {
        self.storyRepository = storyRepository
    }

    func execute(storyId: String) async throws {
        try await storyRepository.markViewed(storyId: storyId)
    }
}
