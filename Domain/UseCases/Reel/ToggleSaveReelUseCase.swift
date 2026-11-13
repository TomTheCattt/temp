//
//  ToggleSaveReelUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - ToggleSaveReelUseCase

protocol ToggleSaveReelUseCaseProtocol: Sendable {
    func execute(reelId: String, shouldSave: Bool) async throws
}

final class ToggleSaveReelUseCase: ToggleSaveReelUseCaseProtocol, Sendable {

    private let reelRepository: ReelRepositoryProtocol

    init(reelRepository: ReelRepositoryProtocol) {
        self.reelRepository = reelRepository
    }

    func execute(reelId: String, shouldSave: Bool) async throws {
        if shouldSave {
            try await reelRepository.saveReel(id: reelId)
        } else {
            try await reelRepository.unsaveReel(id: reelId)
        }
    }
}
