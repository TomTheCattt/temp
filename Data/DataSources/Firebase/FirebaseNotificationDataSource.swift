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
        let fallbackId = (data["actorId"] as? String) ?? (data["senderId"] as? String) ?? ""
        let actor = parseUser(actorData, rootData: data, fallbackId: fallbackId)
        let typeRaw = (data["type"] as? String)?.lowercased() ?? "like"
        let type = NotificationType(rawValue: typeRaw) ?? .like
        let postId = data["postId"] as? String
        let postThumbStr = (data["postThumbnailUrl"] as? String) ?? (data["mediaUrl"] as? String)
        let postThumb = postThumbStr.flatMap { URL(string: $0) }
        let commentText = (data["commentText"] as? String) ?? (data["message"] as? String)
        let isRead = (data["isRead"] as? Bool) ?? (data["read"] as? Bool) ?? false
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

    private func parseUser(_ authorDict: [String: Any]?, rootData: [String: Any], fallbackId: String) -> User {
        let username = (authorDict?["username"] as? String)
            ?? (rootData["senderUsername"] as? String)
            ?? (rootData["actorUsername"] as? String)
            ?? (rootData["username"] as? String)
            ?? "user"
        let fullName = (authorDict?["fullName"] as? String)
            ?? (rootData["senderFullName"] as? String)
            ?? (rootData["actorFullName"] as? String)
            ?? username.capitalized
        let avatarStr = (authorDict?["avatarUrl"] as? String)
            ?? (authorDict?["avatarURL"] as? String)
            ?? (rootData["senderPhotoUrl"] as? String)
            ?? (rootData["actorPhotoUrl"] as? String)
            ?? (rootData["avatarUrl"] as? String)
            ?? (rootData["avatarURL"] as? String)
        let avatarURL = avatarStr.flatMap { URL(string: $0) }
        let isVerified = (authorDict?["isVerified"] as? Bool)
            ?? (rootData["isVerified"] as? Bool)
            ?? false

        return User(
            id: authorDict?["id"] as? String ?? fallbackId,
            username: username,
            fullName: fullName,
            email: authorDict?["email"] as? String,
            phone: authorDict?["phone"] as? String,
            avatarURL: avatarURL,
            bio: authorDict?["bio"] as? String,
            website: authorDict?["website"] as? String,
            isVerified: isVerified,
            isPrivate: authorDict?["isPrivate"] as? Bool ?? false,
            followersCount: authorDict?["followersCount"] as? Int ?? 0,
            followingCount: authorDict?["followingCount"] as? Int ?? 0,
            postsCount: authorDict?["postsCount"] as? Int ?? 0,
            createdAt: parseDate(authorDict?["createdAt"] ?? rootData["createdAt"]),
            isFollowing: authorDict?["isFollowing"] as? Bool ?? false,
            isFollowedBy: authorDict?["isFollowedBy"] as? Bool ?? false,
            isBlocked: authorDict?["isBlocked"] as? Bool ?? false
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
