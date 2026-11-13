//
//  FetchUserReelsUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - FetchUserReelsUseCase

protocol FetchUserReelsUseCaseProtocol: Sendable {
    func execute(userId: String, page: Int, perPage: Int) async throws -> (reels: [Reel], page: Int, perPage: Int, total: Int, hasMore: Bool)
}

final class FetchUserReelsUseCase: FetchUserReelsUseCaseProtocol, Sendable {

    private let reelRepository: ReelRepositoryProtocol

    init(reelRepository: ReelRepositoryProtocol) {
        self.reelRepository = reelRepository
    }

    func execute(userId: String, page: Int = 1, perPage: Int = 24) async throws -> (reels: [Reel], page: Int, perPage: Int, total: Int, hasMore: Bool) {
        try await reelRepository.fetchUserReels(userId: userId, page: page, perPage: perPage)
    }
}
