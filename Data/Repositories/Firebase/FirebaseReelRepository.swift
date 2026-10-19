//
//  FirebaseReelRepository.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation

// MARK: - FirebaseReelRepository

final class FirebaseReelRepository: ReelRepositoryProtocol, @unchecked Sendable {

    private let dataSource: FirebaseReelDataSource

    init(dataSource: FirebaseReelDataSource = FirebaseReelDataSource()) {
        self.dataSource = dataSource
    }

    func fetchReels(page: Int, perPage: Int) async throws -> [Reel] {
        try await dataSource.fetchReels(page: page, perPage: perPage)
    }

    func fetchUserReels(userId: String, page: Int, perPage: Int) async throws -> [Reel] {
        try await dataSource.fetchUserReels(userId: userId, page: page, perPage: perPage)
    }

    func createReel(videoData: Data, caption: String?, audioTrackId: String?) async throws -> Reel {
        try await dataSource.createReel(videoData: videoData, caption: caption, audioTrackId: audioTrackId)
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
        try await dataSource.deleteReel(id: id)
    }
}
