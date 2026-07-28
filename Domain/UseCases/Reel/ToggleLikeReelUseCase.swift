//
//  ToggleLikeReelUseCase.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - ToggleLikeReelInput

struct ToggleLikeReelInput: Sendable {
    let reelId: String
    let isCurrentlyLiked: Bool
}

// MARK: - ToggleLikeReelUseCase

protocol ToggleLikeReelUseCaseProtocol: Sendable {
    func execute(_ input: ToggleLikeReelInput) async throws
}

final class ToggleLikeReelUseCase: ToggleLikeReelUseCaseProtocol, Sendable {

    private let reelRepository: ReelRepositoryProtocol

    init(reelRepository: ReelRepositoryProtocol) {
        self.reelRepository = reelRepository
    }

    func execute(_ input: ToggleLikeReelInput) async throws {
        if input.isCurrentlyLiked {
            try await reelRepository.unlikeReel(id: input.reelId)
        } else {
            try await reelRepository.likeReel(id: input.reelId)
        }
    }
}
