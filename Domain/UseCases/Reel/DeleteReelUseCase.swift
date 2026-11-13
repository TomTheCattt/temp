//
//  DeleteReelUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - DeleteReelUseCase

protocol DeleteReelUseCaseProtocol: Sendable {
    func execute(id: String) async throws
}

final class DeleteReelUseCase: DeleteReelUseCaseProtocol, Sendable {

    private let reelRepository: ReelRepositoryProtocol

    init(reelRepository: ReelRepositoryProtocol) {
        self.reelRepository = reelRepository
    }

    func execute(id: String) async throws {
        try await reelRepository.deleteReel(id: id)
    }
}
