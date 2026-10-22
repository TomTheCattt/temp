//
//  FirebaseStoryDataSource.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - FirebaseStoryDataSource

actor FirebaseStoryDataSource: Sendable {

    private let firestore: Firestore
    private var storageService: FirebaseStorageServiceProtocol
    private var cachedStories: [Story] = []

    init(
        firestore: Firestore = Firestore.firestore(),
        storageService: FirebaseStorageServiceProtocol = FirebaseStorageService.shared
    ) {
        self.firestore = firestore
        self.storageService = storageService
    }

    // MARK: - Fetch Stories

    func fetchStories() async throws -> [Story] {
        let currentUserId = await resolveCurrentUserId()

        do {
            let snapshot = try await firestore.collection("stories")
                .whereField("expiresAt", isGreaterThan: Timestamp(date: Date()))
                .order(by: "expiresAt", descending: false)
                .getDocuments()

            if !snapshot.documents.isEmpty {
                let stories = snapshot.documents.compactMap { doc -> Story? in
                    parseStory(doc.data(), documentId: doc.documentID, currentUserId: currentUserId)
                }
                mergeCachedStories(stories)
            }
        } catch {
            AppLogger.network.error("FirebaseStoryDataSource.fetchStories error: \(error.localizedDescription). Falling back to in-memory cache.")
        }

        return cachedStories
    }

    // MARK: - Fetch Story Items for User

    func fetchStoryItems(userId: String) async throws -> [StoryItem] {
        let currentUserId = await resolveCurrentUserId()
        let isCurrent = (userId == currentUserId)
        let effectiveUserId = isCurrent ? currentUserId : userId

        if let story = cachedStories.first(where: {
            $0.author.id == effectiveUserId
        }) {
            return story.items
        }

        do {
            let snapshot = try await firestore.collection("stories")
                .whereField("authorId", isEqualTo: effectiveUserId)
                .limit(to: 1)
                .getDocuments()

            if let doc = snapshot.documents.first,
               let story = parseStory(doc.data(), documentId: doc.documentID, currentUserId: currentUserId) {
                mergeCachedStories([story])
                return story.items
            }
        } catch {
            AppLogger.network.error("FirebaseStoryDataSource.fetchStoryItems error: \(error.localizedDescription)")
        }

        return []
    }

    // MARK: - Create Story

    func createStory(mediaData: Data, type: StoryItem.MediaType, duration: TimeInterval) async throws -> Story {
        let currentUser = await resolveCurrentUser()
        let itemId = "story_item_\(UUID().uuidString.prefix(8))"

        let uploadedURL: URL
        if type == .video {
            let path = "stories/\(currentUser.id)/\(itemId).mp4"
            uploadedURL = try await storageService.uploadVideo(data: mediaData, path: path)
        } else {
            let path = "stories/\(currentUser.id)/\(itemId).jpg"
            uploadedURL = try await storageService.uploadImage(data: mediaData, path: path)
        }

        let newItem = StoryItem(
            id: itemId,
            mediaURL: uploadedURL,
            type: type,
            duration: duration,
            createdAt: .now,
            sticker: nil
        )

        if let myIndex = cachedStories.firstIndex(where: {
            $0.author.id == currentUser.id || $0.author.id == "user_current"
        }) {
            let existing = cachedStories[myIndex]
            var updatedItems = existing.items
            updatedItems.append(newItem)

            let updatedStory = Story(
                id: existing.id,
                author: currentUser,
                items: updatedItems,
                isViewed: false,
                createdAt: .now,
                expiresAt: Date(timeIntervalSinceNow: 24 * 3600)
            )

            let storyData = storyToDict(updatedStory, viewedBy: [])
            do {
                try await firestore.collection("stories").document(existing.id).setData(storyData)
            } catch {
                AppLogger.network.error("FirebaseStoryDataSource.createStory append error: \(error.localizedDescription)")
            }

            cachedStories[myIndex] = updatedStory
            return updatedStory
        } else {
            let storyId = "story_\(UUID().uuidString.prefix(8))"
            let newStory = Story(
                id: storyId,
                author: currentUser,
                items: [newItem],
                isViewed: false,
                createdAt: .now,
                expiresAt: Date(timeIntervalSinceNow: 24 * 3600)
            )

            let storyData = storyToDict(newStory, viewedBy: [])
            do {
                try await firestore.collection("stories").document(storyId).setData(storyData)
            } catch {
                AppLogger.network.error("FirebaseStoryDataSource.createStory error: \(error.localizedDescription)")
            }

            cachedStories.insert(newStory, at: 0)
            return newStory
        }
    }

    // MARK: - Mark Viewed

    func markViewed(storyId: String) async throws {
        let currentUserId = await resolveCurrentUserId()

        do {
            try await firestore.collection("stories").document(storyId).updateData([
                "viewedBy": FieldValue.arrayUnion([currentUserId])
            ])
        } catch {
            AppLogger.network.error("FirebaseStoryDataSource.markViewed error: \(error.localizedDescription)")
        }

        if let index = cachedStories.firstIndex(where: { $0.id == storyId }) {
            let story = cachedStories[index]
            cachedStories[index] = Story(
                id: story.id,
                author: story.author,
                items: story.items,
                isViewed: true,
                createdAt: story.createdAt,
                expiresAt: story.expiresAt
            )
        }
    }

    // MARK: - Delete Story

    func deleteStory(id: String) async throws {
        do {
            try await firestore.collection("stories").document(id).delete()
        } catch {
            AppLogger.network.error("FirebaseStoryDataSource.deleteStory error: \(error.localizedDescription)")
        }
        cachedStories.removeAll { $0.id == id }
    }

    // MARK: - Private Helpers

    private func mergeCachedStories(_ newStories: [Story]) {
        for story in newStories {
            if let idx = cachedStories.firstIndex(where: { $0.id == story.id }) {
                cachedStories[idx] = story
            } else {
                cachedStories.append(story)
            }
        }
    }

    private func parseStory(_ data: [String: Any], documentId: String, currentUserId: String) -> Story? {
        let authorData = data["author"] as? [String: Any]
        let author = parseUser(authorData, rootData: data, fallbackId: data["authorId"] as? String ?? "")
        let createdAt = parseDate(data["createdAt"])
        let expiresAt = parseDate(data["expiresAt"])
        let viewedBy = data["viewedBy"] as? [String] ?? []
        let isViewed = viewedBy.contains(currentUserId)

        var items: [StoryItem] = []
        if let rawItems = data["items"] as? [[String: Any]], !rawItems.isEmpty {
            items = rawItems.compactMap { parseStoryItem($0) }
        } else if let mediaUrlStr = data["mediaUrl"] as? String ?? data["mediaURL"] as? String, let url = URL(string: mediaUrlStr) {
            let isVideo = (data["mediaType"] as? String)?.lowercased() == "video"
            items = [
                StoryItem(
                    id: "\(documentId)_item_0",
                    mediaURL: url,
                    type: isVideo ? .video : .image,
                    duration: 5.0,
                    createdAt: createdAt,
                    sticker: nil
                )
            ]
        }

        return Story(
            id: documentId,
            author: author,
            items: items,
            isViewed: isViewed,
            createdAt: createdAt,
            expiresAt: expiresAt
        )
    }

    private func parseStoryItem(_ dict: [String: Any]) -> StoryItem? {
        let id = dict["id"] as? String ?? UUID().uuidString
        let urlStr = dict["mediaUrl"] as? String ?? dict["mediaURL"] as? String ?? dict["url"] as? String ?? ""
        guard let url = URL(string: urlStr), !urlStr.isEmpty else { return nil }
        let typeStr = (dict["type"] as? String)?.uppercased() ?? "IMAGE"
        let type: StoryItem.MediaType = typeStr == "VIDEO" ? .video : .image
        let duration = dict["duration"] as? Double ?? 5.0
        let createdAt = parseDate(dict["createdAt"])

        let sticker: StoryStickerInfo?
        if let rawSticker = dict["sticker"] as? [String: Any],
           let typeRaw = rawSticker["type"] as? String,
           let stickerType = StoryStickerInfo.StickerType(rawValue: typeRaw) {
            sticker = StoryStickerInfo(type: stickerType, data: rawSticker["data"] as? String)
        } else {
            sticker = nil
        }

        return StoryItem(
            id: id,
            mediaURL: url,
            type: type,
            duration: duration,
            createdAt: createdAt,
            sticker: sticker
        )
    }

    private func storyToDict(_ story: Story, viewedBy: [String]) -> [String: Any] {
        let dict: [String: Any] = [
            "id": story.id,
            "authorId": story.author.id,
            "author": userToDict(story.author),
            "items": story.items.map { storyItemToDict($0) },
            "viewedBy": viewedBy,
            "createdAt": Timestamp(date: story.createdAt),
            "expiresAt": Timestamp(date: story.expiresAt)
        ]
        return dict
    }

    private func storyItemToDict(_ item: StoryItem) -> [String: Any] {
        var dict: [String: Any] = [
            "id": item.id,
            "mediaUrl": item.mediaURL.absoluteString,
            "type": item.type == .video ? "VIDEO" : "IMAGE",
            "duration": item.duration,
            "createdAt": Timestamp(date: item.createdAt)
        ]
        if let sticker = item.sticker {
            var sDict: [String: Any] = ["type": sticker.type.rawValue]
            if let data = sticker.data { sDict["data"] = data }
            dict["sticker"] = sDict
        }
        return dict
    }

    private func userToDict(_ user: User) -> [String: Any] {
        var dict: [String: Any] = [
            "id": user.id,
            "username": user.username,
            "fullName": user.fullName,
            "isVerified": user.isVerified,
            "isPrivate": user.isPrivate,
            "followersCount": user.followersCount,
            "followingCount": user.followingCount,
            "postsCount": user.postsCount
        ]
        if let avatarURL = user.avatarURL?.absoluteString { dict["avatarUrl"] = avatarURL }
        return dict
    }

    private func parseUser(_ authorDict: [String: Any]?, rootData: [String: Any], fallbackId: String) -> User {
        let username = (authorDict?["username"] as? String)
            ?? (rootData["authorUsername"] as? String)
            ?? (rootData["username"] as? String)
            ?? "user"
        let fullName = (authorDict?["fullName"] as? String)
            ?? (rootData["authorFullName"] as? String)
            ?? username.capitalized
        let avatarStr = (authorDict?["avatarUrl"] as? String)
            ?? (authorDict?["avatarURL"] as? String)
            ?? (rootData["authorPhotoUrl"] as? String)
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

    private func resolveCurrentUser() async -> User {
        if let sessionUser = await MainActor.run(body: { SessionStore.shared.currentUser }) {
            return sessionUser
        }
        let uid = await resolveCurrentUserId()
        return User(
            id: uid,
            username: "user_\(uid.prefix(6))",
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
}
