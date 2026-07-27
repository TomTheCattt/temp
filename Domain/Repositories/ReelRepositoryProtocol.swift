//
//  ReelRepositoryProtocol.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - ReelRepositoryProtocol

protocol ReelRepositoryProtocol: Sendable {

    /// Fetch reels feed (paginated).
    func fetchReels(page: Int, perPage: Int) async throws -> [Reel]

    /// Fetch reels for a specific user.
    func fetchUserReels(userId: String, page: Int, perPage: Int) async throws -> [Reel]

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
