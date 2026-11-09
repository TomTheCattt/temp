//
//  ReelRepositoryProtocol.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - ReelRepositoryProtocol

protocol ReelRepositoryProtocol: Sendable {

    /// Fetch reels feed (cursor-paginated).
    /// - Parameters:
    ///   - cursor: ISO timestamp cursor for pagination (nil for first page)
    ///   - perPage: Number of items per page (default 20)
    /// - Returns: Tuple of (reels, nextCursor, hasMore)
    func fetchReels(cursor: String?, perPage: Int) async throws -> (reels: [Reel], nextCursor: String?, hasMore: Bool)

    /// Fetch reels for a specific user (cursor-paginated).
    func fetchUserReels(userId: String, cursor: String?, perPage: Int) async throws -> (reels: [Reel], nextCursor: String?, hasMore: Bool)

    /// Create a new reel.
    func createReel(videoData: Data, caption: String?, audioTrackId: String?) async throws -> Reel

    /// Like a reel.
    func likeReel(id: String) async throws

    /// Unlike a reel.
    func unlikeReel(id: String) async throws

    /// Save a reel.
    func saveReel(id: String) async throws

    /// Unsave a reel.
    func unsaveReel(id: String) async throws

    /// Delete a reel.
    func deleteReel(id: String) async throws
}
