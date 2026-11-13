//
//  FetchReelDetailUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - FetchReelDetailUseCase

protocol FetchReelDetailUseCaseProtocol: Sendable {
    func execute(id: String) async throws -> Reel
}

final class FetchReelDetailUseCase: FetchReelDetailUseCaseProtocol, Sendable {

    private let reelRepository: ReelRepositoryProtocol

    init(reelRepository: ReelRepositoryProtocol) {
        self.reelRepository = reelRepository
    }

    func execute(id: String) async throws -> Reel {
        try await reelRepository.fetchReel(id: id)
    }
}
