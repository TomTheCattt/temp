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

    func fetchReels(cursor: String? = nil, perPage: Int = 20) async throws -> (reels: [Reel], nextCursor: String?, hasMore: Bool) {
        let response: PaginatedReelsDTO = try await networkService.requestEnvelope(
            ReelEndpoint.feed(cursor: cursor, perPage: perPage)
        )
        return (ReelMapper.toEntityList(response.items), response.nextCursor, response.hasMore)
    }

    func fetchReel(reelId: String) async throws -> Reel {
        let response: ReelWrapperDTO = try await networkService.requestEnvelope(
            ReelEndpoint.detail(reelId: reelId)
        )
        return ReelMapper.toEntity(response.reel)
    }

    func fetchUserReels(userId: String, page: Int = 1, perPage: Int = 20) async throws -> (reels: [Reel], page: Int, perPage: Int, total: Int, hasMore: Bool) {
        let response: PaginatedReelsDTO = try await networkService.requestEnvelope(
            ReelEndpoint.userReels(userId: userId, page: page, perPage: perPage)
        )
        return (ReelMapper.toEntityList(response.items), response.page ?? page, response.perPage ?? perPage, response.total ?? 0, response.hasMore)
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

    func createReel(videoUrl: String, thumbnailUrl: String?, caption: String?, duration: Double, audioName: String?, audioArtist: String?, audioCoverUrl: String?, isOriginalAudio: Bool?) async throws -> Reel {
        let wrapper: ReelWrapperDTO = try await networkService.requestEnvelope(
            ReelEndpoint.create(videoUrl: videoUrl, thumbnailUrl: thumbnailUrl, caption: caption, duration: duration, audioName: audioName, audioArtist: audioArtist, audioCoverUrl: audioCoverUrl, isOriginalAudio: isOriginalAudio)
        )
        return ReelMapper.toEntity(wrapper.reel)
    }

    // MARK: - Comments

    func fetchReelComments(reelId: String, page: Int, perPage: Int) async throws -> (comments: [Comment], page: Int, perPage: Int, total: Int, hasMore: Bool) {
        let response: PaginatedCommentsDTO = try await networkService.requestEnvelope(
            ReelEndpoint.comments(reelId: reelId, page: page, perPage: perPage)
        )
        return (CommentMapper.toEntityList(response.items), response.page, response.perPage, response.total, response.hasMore)
    }

    func addReelComment(reelId: String, text: String, parentId: String?) async throws -> Comment {
        let wrapper: CommentWrapperDTO = try await networkService.requestEnvelope(
            ReelEndpoint.addComment(reelId: reelId, text: text, parentId: parentId)
        )
        return CommentMapper.toEntity(wrapper.comment)
    }

    func deleteReelComment(reelId: String, commentId: String) async throws {
        try await networkService.requestVoid(ReelEndpoint.deleteComment(reelId: reelId, commentId: commentId))
    }
}
