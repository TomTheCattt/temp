//
//  ReelRepository.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation
import Alamofire

// MARK: - ReelRepository

final class ReelRepository: ReelRepositoryProtocol, @unchecked Sendable {

    private let remoteDataSource: RemoteReelDataSource
    private let networkService: NetworkServiceProtocol

    init(
        remoteDataSource: RemoteReelDataSource,
        networkService: NetworkServiceProtocol
    ) {
        self.remoteDataSource = remoteDataSource
        self.networkService = networkService
    }

    func fetchReels(page: Int, perPage: Int) async throws -> [Reel] {
        try await remoteDataSource.fetchReels(page: page, perPage: perPage)
    }

    func fetchUserReels(userId: String, page: Int, perPage: Int) async throws -> [Reel] {
        try await remoteDataSource.fetchUserReels(userId: userId, page: page, perPage: perPage)
    }

    func createReel(videoData: Data, caption: String?, audioTrackId: String?) async throws -> Reel {
        // Step 1: Upload video
        let uploadResponse: UploadVideoResponseDTO = try await networkService.upload(UploadEndpoint.video) { formData in
            formData.append(videoData, withName: "file", fileName: "reel.mp4", mimeType: "video/mp4")
        }

        // Step 2: Create reel with uploaded URL
        return try await remoteDataSource.createReel(
            videoUrl: uploadResponse.url,
            thumbnailUrl: uploadResponse.thumbnailUrl,
            caption: caption,
            duration: uploadResponse.duration ?? 15,
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
