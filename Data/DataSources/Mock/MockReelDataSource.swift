//
//  MockReelDataSource.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation
import os

// MARK: - MockReelStore

/// In-memory store for reels so like and save states persist across views.
final class MockReelStore: @unchecked Sendable {

    static let shared = MockReelStore()

    private let lock = OSAllocatedUnfairLock()
    private var _reels: [Reel] = MockData.reels

    private init() {}

    var reels: [Reel] {
        get { lock.withLock { _reels } }
        set { lock.withLock { _reels = newValue } }
    }

    func insert(_ reel: Reel, at index: Int = 0) {
        lock.lock(); defer { lock.unlock() }
        _reels.insert(reel, at: index)
    }

    func update(id: String, mutate: (inout Reel) -> Void) -> Reel? {
        lock.lock(); defer { lock.unlock() }
        guard let idx = _reels.firstIndex(where: { $0.id == id }) else { return nil }
        mutate(&_reels[idx])
        return _reels[idx]
    }

    @discardableResult
    func toggleLike(id: String, isLiked: Bool) -> Reel? {
        update(id: id) { reel in
            let wasLiked = reel.isLiked
            guard wasLiked != isLiked else { return }
            let delta = isLiked ? 1 : -1
            reel = reel.copy(
                likesCount: max(0, reel.likesCount + delta),
                isLiked: isLiked
            )
        }
    }

    @discardableResult
    func toggleSave(id: String, isSaved: Bool) -> Reel? {
        update(id: id) { reel in
            reel = reel.copy(isSaved: isSaved)
        }
    }
}

// MARK: - MockReelDataSource

final class MockReelDataSource: @unchecked Sendable {

    private var store: MockReelStore { MockReelStore.shared }

    func fetchReels(page: Int, perPage: Int) async throws -> [Reel] {
        try await simulateDelay()
        let all = store.reels
        let start = (page - 1) * perPage
        let end = min(start + perPage, all.count)
        guard start < end else { return [] }
        return Array(all[start..<end])
    }

    func fetchUserReels(userId: String, page: Int, perPage: Int) async throws -> [Reel] {
        try await simulateDelay()
        let currentUserId = SessionStore.shared.currentUserId
        let isCurrent = (userId == currentUserId || userId == "user_current" || (currentUserId.isEmpty && userId == MockData.currentUser.id))
        let all = store.reels
        let userReels = isCurrent
            ? all.filter { $0.author.id == "user_current" || $0.author.id == currentUserId }
            : all.filter { $0.author.id == userId }
        let start = (page - 1) * perPage
        let end = min(start + perPage, userReels.count)
        guard start < end else { return [] }
        return Array(userReels[start..<end])
    }

    func likeReel(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
        _ = store.toggleLike(id: id, isLiked: true)
    }

    func unlikeReel(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
        _ = store.toggleLike(id: id, isLiked: false)
    }

    func saveReel(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
        _ = store.toggleSave(id: id, isSaved: true)
    }

    func unsaveReel(id: String) async throws {
        try await simulateDelay(seconds: 0.2)
        _ = store.toggleSave(id: id, isSaved: false)
    }

    // MARK: - Private

    private func simulateDelay(seconds: Double = 0.5) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
