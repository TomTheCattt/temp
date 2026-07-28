//
//  RemoteReelDataSource.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation
import Alamofire

// MARK: - RemoteReelDataSource

final class RemoteReelDataSource: @unchecked Sendable {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func fetchReels(page: Int, perPage: Int) async throws -> [Reel] {
        let response: PaginatedResponseDTO<ReelDTO> = try await networkService.request(
            ReelEndpoint.feed(page: page, perPage: perPage)
        )
        return ReelMapper.toEntityList(response.items)
    }

    func fetchUserReels(userId: String, page: Int, perPage: Int) async throws -> [Reel] {
        let response: PaginatedResponseDTO<ReelDTO> = try await networkService.request(
            ReelEndpoint.userReels(userId: userId, page: page, perPage: perPage)
        )
        return ReelMapper.toEntityList(response.items)
    }

    func createReel(videoData: Data, caption: String?, audioTrackId: String?) async throws -> Reel {
        let dto: ReelDTO = try await networkService.upload(
            ReelEndpoint.create(caption: caption, audioTrackId: audioTrackId)
        ) { formData in
            formData.append(videoData, withName: "video", fileName: "reel.mp4", mimeType: "video/mp4")
        }
        return ReelMapper.toEntity(dto)
    }

    func likeReel(id: String) async throws {
        try await networkService.requestVoid(ReelEndpoint.like(id: id))
    }

    func unlikeReel(id: String) async throws {
        try await networkService.requestVoid(ReelEndpoint.unlike(id: id))
    }

    func saveReel(id: String) async throws {
        try await networkService.requestVoid(ReelEndpoint.save(id: id))
    }

    func unsaveReel(id: String) async throws {
        try await networkService.requestVoid(ReelEndpoint.unsave(id: id))
    }

    func deleteReel(id: String) async throws {
        try await networkService.requestVoid(ReelEndpoint.delete(id: id))
    }
}
