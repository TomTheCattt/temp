//
//  FetchReelsUseCase.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - FetchReelsUseCase

protocol FetchReelsUseCaseProtocol: Sendable {
    func execute(_ input: PaginationInput) async throws -> (reels: [Reel], nextCursor: String?, hasMore: Bool)
}

final class FetchReelsUseCase: FetchReelsUseCaseProtocol, Sendable {

    private let reelRepository: ReelRepositoryProtocol

    init(reelRepository: ReelRepositoryProtocol) {
        self.reelRepository = reelRepository
    }

    func execute(_ input: PaginationInput) async throws -> (reels: [Reel], nextCursor: String?, hasMore: Bool) {
        try await reelRepository.fetchReels(cursor: input.cursor, perPage: input.perPage)
    }
}
