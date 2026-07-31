//
//  ReelRepository.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - ReelRepository

final class ReelRepository: ReelRepositoryProtocol, @unchecked Sendable {

    private let remoteDataSource: RemoteReelDataSource
    private let mockDataSource: MockReelDataSource

    init(
        remoteDataSource: RemoteReelDataSource,
        mockDataSource: MockReelDataSource = MockReelDataSource()
    ) {
        self.remoteDataSource = remoteDataSource
        self.mockDataSource = mockDataSource
    }

    func fetchReels(page: Int, perPage: Int) async throws -> [Reel] {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchReels(page: page, perPage: perPage)
        }
        return try await remoteDataSource.fetchReels(page: page, perPage: perPage)
    }

    func fetchUserReels(userId: String, page: Int, perPage: Int) async throws -> [Reel] {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchUserReels(userId: userId, page: page, perPage: perPage)
        }
        return try await remoteDataSource.fetchUserReels(userId: userId, page: page, perPage: perPage)
    }

    func createReel(videoData: Data, caption: String?, audioTrackId: String?) async throws -> Reel {
        guard !AppConfig.shared.isMockAPI else {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            let currentUser = SessionStore.shared.currentUser!
            return Reel(
                id: "reel_\(UUID().uuidString.prefix(8))",
                author: currentUser,
                videoURL: URL(string: "https://example.com/video.mp4")!,
                thumbnailURL: nil,
                caption: caption,
                audioTrack: nil,
                likesCount: 0,
                commentsCount: 0,
                sharesCount: 0,
                viewsCount: 0,
                duration: 15,
                isLiked: false,
                isSaved: false,
                createdAt: .now
            )
        }
        return try await remoteDataSource.createReel(videoData: videoData, caption: caption, audioTrackId: audioTrackId)
    }

    func likeReel(id: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.likeReel(id: id)
        }
        try await remoteDataSource.likeReel(id: id)
    }

    func unlikeReel(id: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.unlikeReel(id: id)
        }
        try await remoteDataSource.unlikeReel(id: id)
    }

    func saveReel(id: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.saveReel(id: id)
        }
        try await remoteDataSource.saveReel(id: id)
    }

    func unsaveReel(id: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.unsaveReel(id: id)
        }
        try await remoteDataSource.unsaveReel(id: id)
    }

    func deleteReel(id: String) async throws {
        guard !AppConfig.shared.isMockAPI else {
            try await Task.sleep(nanoseconds: 300_000_000)
            return
        }
        try await remoteDataSource.deleteReel(id: id)
    }
}
