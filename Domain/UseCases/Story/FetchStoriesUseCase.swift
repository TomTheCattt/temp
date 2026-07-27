//
//  FetchStoriesUseCase.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - FetchStoriesUseCase

protocol FetchStoriesUseCaseProtocol: Sendable {
    func execute() async throws -> [Story]
}

final class FetchStoriesUseCase: FetchStoriesUseCaseProtocol, Sendable {

    private let storyRepository: StoryRepositoryProtocol

    init(storyRepository: StoryRepositoryProtocol) {
        self.storyRepository = storyRepository
    }

    func execute() async throws -> [Story] {
        try await storyRepository.fetchStories()
    }
}
