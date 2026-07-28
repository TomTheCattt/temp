//
//  MockReelDataSource.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - MockReelDataSource

final class MockReelDataSource: Sendable {

    func fetchReels(page: Int, perPage: Int) async throws -> [Reel] {
        try await simulateDelay()
        let start = (page - 1) * perPage
        let end = min(start + perPage, MockData.reels.count)
        guard start < end else { return [] }
        return Array(MockData.reels[start..<end])
    }

    func fetchUserReels(userId: String, page: Int, perPage: Int) async throws -> [Reel] {
        try await simulateDelay()
        return MockData.reels.filter { $0.author.id == userId }
    }

    func likeReel(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
    }

    func unlikeReel(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
    }

    func saveReel(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
    }

    func unsaveReel(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
    }

    // MARK: - Private

    private func simulateDelay(seconds: Double = 0.6) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
