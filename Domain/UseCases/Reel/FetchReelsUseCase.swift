//
//  FetchReelsUseCase.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - FetchReelsUseCase

protocol FetchReelsUseCaseProtocol: Sendable {
    func execute(_ input: PaginationInput) async throws -> [Reel]
}

final class FetchReelsUseCase: FetchReelsUseCaseProtocol, Sendable {

    private let reelRepository: ReelRepositoryProtocol

    init(reelRepository: ReelRepositoryProtocol) {
        self.reelRepository = reelRepository
    }

    func execute(_ input: PaginationInput) async throws -> [Reel] {
        try await reelRepository.fetchReels(page: input.page, perPage: input.perPage)
    }
}
