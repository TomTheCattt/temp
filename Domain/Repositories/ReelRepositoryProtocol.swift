//
//  ReelRepositoryProtocol.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - ReelRepositoryProtocol

protocol ReelRepositoryProtocol: Sendable {

    /// Fetch a single reel by ID.
    func fetchReel(id: String) async throws -> Reel

    /// Fetch reels feed (cursor-paginated).
    /// - Parameters:
    ///   - cursor: ISO timestamp cursor for pagination (nil for first page)
    ///   - perPage: Number of items per page (default 20)
    /// - Returns: Tuple of (reels, nextCursor, hasMore)
    func fetchReels(cursor: String?, perPage: Int) async throws -> (reels: [Reel], nextCursor: String?, hasMore: Bool)

    /// Fetch reels for a specific user (offset-paginated).
    func fetchUserReels(userId: String, page: Int, perPage: Int) async throws -> (reels: [Reel], page: Int, perPage: Int, total: Int, hasMore: Bool)

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

    /// Fetch comments for a reel (offset-based pagination).
    func fetchReelComments(reelId: String, page: Int, perPage: Int) async throws -> (comments: [Comment], page: Int, perPage: Int, total: Int, hasMore: Bool)

    /// Add a comment to a reel.
    func addReelComment(reelId: String, text: String, parentId: String?) async throws -> Comment

    /// Delete a comment on a reel.
    func deleteReelComment(reelId: String, commentId: String) async throws
}
