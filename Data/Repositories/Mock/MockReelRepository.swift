//
//  MockReelRepository.swift
//  Instagram
//
//  Created by Kiro on 5/8/26.
//

import Foundation

// MARK: - MockReelRepository

/// Mock implementation of ReelRepositoryProtocol for UI testing with local data.
final class MockReelRepository: ReelRepositoryProtocol, @unchecked Sendable {

    private let dataSource = MockReelDataSource()

    func fetchReels(page: Int, perPage: Int) async throws -> [Reel] {
        try await dataSource.fetchReels(page: page, perPage: perPage)
    }

    func fetchUserReels(userId: String, page: Int, perPage: Int) async throws -> [Reel] {
        try await dataSource.fetchUserReels(userId: userId, page: page, perPage: perPage)
    }

    func createReel(videoData: Data, caption: String?, audioTrackId: String?) async throws -> Reel {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return MockData.reels.first!
    }

    func likeReel(id: String) async throws {
        try await dataSource.likeReel(id: id)
    }

    func unlikeReel(id: String) async throws {
        try await dataSource.unlikeReel(id: id)
    }

    func saveReel(id: String) async throws {
        try await dataSource.saveReel(id: id)
    }

    func unsaveReel(id: String) async throws {
        try await dataSource.unsaveReel(id: id)
    }

    func deleteReel(id: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }
}
