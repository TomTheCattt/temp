//
//  FirebaseNotificationDataSource.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - FirebaseNotificationDataSource

actor FirebaseNotificationDataSource: Sendable {

    private let firestore: Firestore
    private var cachedNotifications: [AppNotification] = []

    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }

    // MARK: - Fetch Notifications

    func fetchNotifications(page: Int, perPage: Int) async throws -> [AppNotification] {
        let currentUserId = await resolveCurrentUserId()

        do {
            let snapshot = try await firestore.collection("notifications")
                .whereField("recipientId", isEqualTo: currentUserId)
                .order(by: "createdAt", descending: true)
                .limit(to: perPage * page)
                .getDocuments()

            if !snapshot.documents.isEmpty {
                let notifications = snapshot.documents.compactMap { doc -> AppNotification? in
                    parseNotification(doc.data(), documentId: doc.documentID)
                }
                mergeCachedNotifications(notifications)
            }
        } catch {
            AppLogger.network.error("FirebaseNotificationDataSource.fetchNotifications error: \(error.localizedDescription). Falling back to in-memory cache.")
        }

        let start = (page - 1) * perPage
        let end = min(start + perPage, cachedNotifications.count)
        guard start < end else { return [] }
        return Array(cachedNotifications[start..<end])
    }

    // MARK: - Mark As Read

    func markAsRead(id: String) async throws {
        do {
            try await firestore.collection("notifications").document(id).updateData([
                "isRead": true
            ])
        } catch {
            AppLogger.network.error("FirebaseNotificationDataSource.markAsRead error: \(error.localizedDescription)")
        }

        if let index = cachedNotifications.firstIndex(where: { $0.id == id }) {
            let n = cachedNotifications[index]
            cachedNotifications[index] = AppNotification(
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

    // MARK: - Mark All As Read

    func markAllAsRead() async throws {
        let currentUserId = await resolveCurrentUserId()

        do {
            let snapshot = try await firestore.collection("notifications")
                .whereField("recipientId", isEqualTo: currentUserId)
                .whereField("isRead", isEqualTo: false)
                .getDocuments()

            if !snapshot.documents.isEmpty {
                let batch = firestore.batch()
                for doc in snapshot.documents {
                    batch.updateData(["isRead": true], forDocument: doc.reference)
                }
                try await batch.commit()
            }
        } catch {
            AppLogger.network.error("FirebaseNotificationDataSource.markAllAsRead error: \(error.localizedDescription)")
        }

        cachedNotifications = cachedNotifications.map { n in
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

    // MARK: - Fetch Unread Count

    func fetchUnreadCount() async throws -> Int {
        let currentUserId = await resolveCurrentUserId()

        do {
            let snapshot = try await firestore.collection("notifications")
                .whereField("recipientId", isEqualTo: currentUserId)
                .whereField("isRead", isEqualTo: false)
                .getDocuments()

            return snapshot.documents.count
        } catch {
            AppLogger.network.error("FirebaseNotificationDataSource.fetchUnreadCount error: \(error.localizedDescription)")
        }

        return cachedNotifications.filter { !$0.isRead }.count
    }

    // MARK: - Private Helpers

    private func mergeCachedNotifications(_ newNotifications: [AppNotification]) {
        for n in newNotifications {
            if let idx = cachedNotifications.firstIndex(where: { $0.id == n.id }) {
                cachedNotifications[idx] = n
            } else {
                cachedNotifications.append(n)
            }
        }
    }

    private func parseNotification(_ data: [String: Any], documentId: String) -> AppNotification? {
        let actorData = data["actor"] as? [String: Any]
        let actor = parseUser(actorData, fallbackId: data["actorId"] as? String ?? "")
        let typeRaw = (data["type"] as? String)?.lowercased() ?? "like"
        let type = NotificationType(rawValue: typeRaw) ?? .like
        let postId = data["postId"] as? String
        let postThumb = (data["postThumbnailUrl"] as? String).flatMap { URL(string: $0) }
        let commentText = data["commentText"] as? String
        let isRead = data["isRead"] as? Bool ?? false
        let createdAt = parseDate(data["createdAt"])

        return AppNotification(
            id: documentId,
            type: type,
            actor: actor,
            postId: postId,
            postThumbnailURL: postThumb,
            commentText: commentText,
            isRead: isRead,
            createdAt: createdAt
        )
    }

    private func parseUser(_ data: [String: Any]?, fallbackId: String) -> User {
        guard let data else {
            return User(
                id: fallbackId,
                username: "user",
                fullName: "Instagram User",
                email: nil,
                phone: nil,
                avatarURL: nil,
                bio: nil,
                website: nil,
                isVerified: false,
                isPrivate: false,
                followersCount: 0,
                followingCount: 0,
                postsCount: 0,
                createdAt: .now,
                isFollowing: false,
                isFollowedBy: false,
                isBlocked: false
            )
        }
        return User(
            id: data["id"] as? String ?? fallbackId,
            username: data["username"] as? String ?? "user",
            fullName: data["fullName"] as? String ?? "Instagram User",
            email: data["email"] as? String,
            phone: data["phone"] as? String,
            avatarURL: (data["avatarUrl"] as? String).flatMap { URL(string: $0) },
            bio: data["bio"] as? String,
            website: data["website"] as? String,
            isVerified: data["isVerified"] as? Bool ?? false,
            isPrivate: data["isPrivate"] as? Bool ?? false,
            followersCount: data["followersCount"] as? Int ?? 0,
            followingCount: data["followingCount"] as? Int ?? 0,
            postsCount: data["postsCount"] as? Int ?? 0,
            createdAt: parseDate(data["createdAt"]),
            isFollowing: data["isFollowing"] as? Bool ?? false,
            isFollowedBy: data["isFollowedBy"] as? Bool ?? false,
            isBlocked: data["isBlocked"] as? Bool ?? false
        )
    }

    private func parseDate(_ value: Any?) -> Date {
        if let timestamp = value as? Timestamp {
            return timestamp.dateValue()
        }
        if let dateString = value as? String {
            return DateMapper.toDate(dateString)
        }
        if let date = value as? Date {
            return date
        }
        return .now
    }

    private func resolveCurrentUserId() async -> String {
        let authUid = await MainActor.run { FirebaseAuthService.shared.currentUserUID }
        if let authUid, !authUid.isEmpty {
            return authUid
        }
        let sessionUid = await MainActor.run { SessionStore.shared.currentUserId }
        return sessionUid
    }
}
