//
//  RemoteReelDataSource.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - RemoteReelDataSource

final class RemoteReelDataSource: @unchecked Sendable {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    // MARK: - Feed

    func fetchReels(page: Int, perPage: Int) async throws -> [Reel] {
        let response: PaginatedReelsDTO = try await networkService.requestEnvelope(
            ReelEndpoint.feed(page: page, perPage: perPage)
        )
        return ReelMapper.toEntityList(response.items)
    }

    func fetchUserReels(userId: String, page: Int, perPage: Int) async throws -> [Reel] {
        let response: PaginatedReelsDTO = try await networkService.requestEnvelope(
            ReelEndpoint.userReels(userId: userId, page: page, perPage: perPage)
        )
        return ReelMapper.toEntityList(response.items)
    }

    // MARK: - Like / Unlike

    func likeReel(id: String) async throws {
        try await networkService.requestVoid(ReelEndpoint.like(id: id))
    }

    func unlikeReel(id: String) async throws {
        try await networkService.requestVoid(ReelEndpoint.unlike(id: id))
    }

    // MARK: - Save / Unsave

    func saveReel(id: String) async throws {
        try await networkService.requestVoid(ReelEndpoint.save(id: id))
    }

    func unsaveReel(id: String) async throws {
        try await networkService.requestVoid(ReelEndpoint.unsave(id: id))
    }

    // MARK: - View

    func viewReel(id: String) async throws {
        try await networkService.requestVoid(ReelEndpoint.view(id: id))
    }

    // MARK: - Delete

    func deleteReel(id: String) async throws {
        try await networkService.requestVoid(ReelEndpoint.delete(id: id))
    }

    // MARK: - Create

    func createReel(videoUrl: String, thumbnailUrl: String?, caption: String?, duration: Double, audioName: String?, audioArtist: String?) async throws -> Reel {
        let wrapper: ReelWrapperDTO = try await networkService.requestEnvelope(
            ReelEndpoint.create(videoUrl: videoUrl, thumbnailUrl: thumbnailUrl, caption: caption, duration: duration, audioName: audioName, audioArtist: audioArtist)
        )
        return ReelMapper.toEntity(wrapper.reel)
    }
}
