//
//  StoryRepliesUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - StoryRepliesUseCase

protocol StoryRepliesUseCaseProtocol: Sendable {
    func fetchReplies(storyId: String) async throws -> StoryRepliesResult
    func replyToStory(storyId: String, text: String) async throws -> StoryReply
    func deleteReply(replyId: String) async throws
    func deleteAllReplies(storyId: String) async throws
    func setRepliesEnabled(storyId: String, enabled: Bool) async throws
}

final class StoryRepliesUseCase: StoryRepliesUseCaseProtocol, Sendable {

    private let storyRepository: StoryRepositoryProtocol

    init(storyRepository: StoryRepositoryProtocol) {
        self.storyRepository = storyRepository
    }

    func fetchReplies(storyId: String) async throws -> StoryRepliesResult {
        try await storyRepository.fetchStoryReplies(storyId: storyId)
    }

    func replyToStory(storyId: String, text: String) async throws -> StoryReply {
        try await storyRepository.replyToStory(storyId: storyId, text: text)
    }

    func deleteReply(replyId: String) async throws {
        try await storyRepository.deleteStoryReply(replyId: replyId)
    }

    func deleteAllReplies(storyId: String) async throws {
        try await storyRepository.deleteAllStoryReplies(storyId: storyId)
    }

    func setRepliesEnabled(storyId: String, enabled: Bool) async throws {
        try await storyRepository.setStoryRepliesEnabled(storyId: storyId, enabled: enabled)
    }
}
