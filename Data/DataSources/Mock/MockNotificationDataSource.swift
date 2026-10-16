//
//  MockNotificationDataSource.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import os

// MARK: - MockNotificationStore

/// In-memory store for notifications so read states and unread counts
/// persist across screens and trigger correct UI badge updates.
final class MockNotificationStore: @unchecked Sendable {

    static let shared = MockNotificationStore()

    private let lock = OSAllocatedUnfairLock()
    private var _notifications: [AppNotification] = MockData.notifications

    private init() {}

    var notifications: [AppNotification] {
        get { lock.withLock { _notifications } }
        set { lock.withLock { _notifications = newValue } }
    }

    var unreadCount: Int {
        lock.lock(); defer { lock.unlock() }
        return _notifications.filter { !$0.isRead }.count
    }

    func markAsRead(id: String) {
        lock.lock(); defer { lock.unlock() }
        guard let index = _notifications.firstIndex(where: { $0.id == id }) else { return }
        let n = _notifications[index]
        _notifications[index] = AppNotification(
            id: n.id,
            type: n.type,
            actor: n.actor,
            postId: n.postId,
            postThumbnailURL: n.postThumbnailURL,
            commentText: n.commentText,
            isRead: true,
            createdAt: n.createdAt
        )
    }

    func markAllAsRead() {
        lock.lock(); defer { lock.unlock() }
        _notifications = _notifications.map { n in
            AppNotification(
                id: n.id,
                type: n.type,
                actor: n.actor,
                postId: n.postId,
                postThumbnailURL: n.postThumbnailURL,
                commentText: n.commentText,
                isRead: true,
                createdAt: n.createdAt
            )
        }
    }
}

// MARK: - MockNotificationDataSource

final class MockNotificationDataSource: @unchecked Sendable {

    private var store: MockNotificationStore { MockNotificationStore.shared }

    func fetchNotifications(page: Int, perPage: Int) async throws -> [AppNotification] {
        try await simulateDelay()
        let all = store.notifications
        let start = (page - 1) * perPage
        let end = min(start + perPage, all.count)
        guard start < end else { return [] }
        return Array(all[start..<end])
    }

    func markAsRead(id: String) async throws {
        try await simulateDelay(seconds: 0.1)
        store.markAsRead(id: id)
    }

    func markAllAsRead() async throws {
        try await simulateDelay(seconds: 0.2)
        store.markAllAsRead()
    }

    func fetchUnreadCount() async throws -> Int {
        try await simulateDelay(seconds: 0.1)
        return store.unreadCount
    }

    // MARK: - Private

    private func simulateDelay(seconds: Double = 0.4) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
