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
    private let uploadDataSource: RemoteUploadDataSource

    init(
        remoteDataSource: RemoteReelDataSource,
        uploadDataSource: RemoteUploadDataSource
    ) {
        self.remoteDataSource = remoteDataSource
        self.uploadDataSource = uploadDataSource
    }

    func fetchReels(cursor: String?, perPage: Int) async throws -> (reels: [Reel], nextCursor: String?, hasMore: Bool) {
        try await remoteDataSource.fetchReels(cursor: cursor, perPage: perPage)
    }

    func fetchUserReels(userId: String, cursor: String?, perPage: Int) async throws -> (reels: [Reel], nextCursor: String?, hasMore: Bool) {
        try await remoteDataSource.fetchUserReels(userId: userId, cursor: cursor, perPage: perPage)
    }

    func createReel(videoData: Data, caption: String?, audioTrackId: String?) async throws -> Reel {
        // Step 1: Upload video using presigned URL
        let uploadResult = try await uploadDataSource.uploadPresigned(
            data: videoData,
            category: .reel
        )

        // Step 2: Create reel with uploaded URL
        return try await remoteDataSource.createReel(
            videoUrl: uploadResult.url,
            thumbnailUrl: nil, // Thumbnail would need to be uploaded separately
            caption: caption,
            duration: uploadResult.duration ?? 15,
            audioName: nil,
            audioArtist: nil
        )
    }

    func likeReel(id: String) async throws {
        try await remoteDataSource.likeReel(id: id)
    }

    func unlikeReel(id: String) async throws {
        try await remoteDataSource.unlikeReel(id: id)
    }

    func saveReel(id: String) async throws {
        try await remoteDataSource.saveReel(id: id)
    }

    func unsaveReel(id: String) async throws {
        try await remoteDataSource.unsaveReel(id: id)
    }

    func deleteReel(id: String) async throws {
        try await remoteDataSource.deleteReel(id: id)
    }
}