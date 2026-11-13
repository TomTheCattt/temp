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

    func fetchReel(id: String) async throws -> Reel {
        try await remoteDataSource.fetchReel(reelId: id)
    }

    func fetchUserReels(userId: String, page: Int, perPage: Int) async throws -> (reels: [Reel], page: Int, perPage: Int, total: Int, hasMore: Bool) {
        try await remoteDataSource.fetchUserReels(userId: userId, page: page, perPage: perPage)
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
            audioArtist: nil,
            audioCoverUrl: nil,
            isOriginalAudio: nil
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

    // MARK: - Comments

    func fetchReelComments(reelId: String, page: Int, perPage: Int) async throws -> (comments: [Comment], page: Int, perPage: Int, total: Int, hasMore: Bool) {
        try await remoteDataSource.fetchReelComments(reelId: reelId, page: page, perPage: perPage)
    }

    func addReelComment(reelId: String, text: String, parentId: String?) async throws -> Comment {
        try await remoteDataSource.addReelComment(reelId: reelId, text: text, parentId: parentId)
    }

    func deleteReelComment(reelId: String, commentId: String) async throws {
        try await remoteDataSource.deleteReelComment(reelId: reelId, commentId: commentId)
    }
}