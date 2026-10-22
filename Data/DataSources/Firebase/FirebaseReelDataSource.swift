//
//  FirebaseReelDataSource.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - FirebaseReelDataSource

actor FirebaseReelDataSource: Sendable {

    private let firestore: Firestore
    private var storageService: FirebaseStorageServiceProtocol
    private var cachedReels: [Reel] = []

    init(
        firestore: Firestore = Firestore.firestore(),
        storageService: FirebaseStorageServiceProtocol = FirebaseStorageService.shared
    ) {
        self.firestore = firestore
        self.storageService = storageService
    }

    // MARK: - Fetch Reels Feed

    func fetchReels(page: Int, perPage: Int) async throws -> [Reel] {
        let currentUserId = await resolveCurrentUserId()

        do {
            let snapshot = try await firestore.collection("reels")
                .order(by: "createdAt", descending: true)
                .limit(to: perPage * page)
                .getDocuments()

            if !snapshot.documents.isEmpty {
                let reels = snapshot.documents.compactMap { doc -> Reel? in
                    parseReel(doc.data(), documentId: doc.documentID, currentUserId: currentUserId)
                }
                mergeCachedReels(reels)
            }
        } catch {
            AppLogger.network.error("FirebaseReelDataSource.fetchReels error: \(error.localizedDescription). Falling back to in-memory cache.")
        }

        let start = (page - 1) * perPage
        let end = min(start + perPage, cachedReels.count)
        guard start < end else { return [] }
        return Array(cachedReels[start..<end])
    }

    // MARK: - Fetch User Reels

    func fetchUserReels(userId: String, page: Int, perPage: Int) async throws -> [Reel] {
        let currentUserId = await resolveCurrentUserId()
        let isCurrent = (userId == currentUserId)
        let effectiveUserId = isCurrent ? currentUserId : userId

        do {
            let snapshot = try await firestore.collection("reels")
                .whereField("authorId", isEqualTo: effectiveUserId)
                .order(by: "createdAt", descending: true)
                .limit(to: perPage * page)
                .getDocuments()

            if !snapshot.documents.isEmpty {
                let reels = snapshot.documents.compactMap { doc -> Reel? in
                    parseReel(doc.data(), documentId: doc.documentID, currentUserId: currentUserId)
                }
                mergeCachedReels(reels)
            }
        } catch {
            AppLogger.network.error("FirebaseReelDataSource.fetchUserReels error: \(error.localizedDescription)")
        }

        let filtered = isCurrent
            ? cachedReels.filter { $0.author.id == currentUserId }
            : cachedReels.filter { $0.author.id == userId }

        let start = (page - 1) * perPage
        let end = min(start + perPage, filtered.count)
        guard start < end else { return [] }
        return Array(filtered[start..<end])
    }

    // MARK: - Create Reel

    func createReel(videoData: Data, caption: String?, audioTrackId: String?) async throws -> Reel {
        let currentUser = await resolveCurrentUser()
        let reelId = "reel_\(UUID().uuidString.prefix(10))"

        let path = "reels/\(currentUser.id)/\(reelId).mp4"
        let videoURL = try await storageService.uploadVideo(data: videoData, path: path)

        let audioTrack: AudioTrack? = audioTrackId != nil ? AudioTrack(
            id: audioTrackId!,
            name: "Original Audio",
            artistName: currentUser.username,
            coverURL: currentUser.avatarURL,
            isOriginal: true
        ) : nil

        let newReel = Reel(
            id: reelId,
            author: currentUser,
            videoURL: videoURL,
            fallbackVideoURL: nil,
            thumbnailURL: nil,
            caption: caption,
            audioTrack: audioTrack,
            likesCount: 0,
            commentsCount: 0,
            sharesCount: 0,
            viewsCount: 0,
            duration: 15.0,
            isLiked: false,
            isSaved: false,
            createdAt: .now
        )

        let reelData = reelToDict(newReel)
        do {
            try await firestore.collection("reels").document(reelId).setData(reelData)
        } catch {
            AppLogger.network.error("FirebaseReelDataSource.createReel error: \(error.localizedDescription)")
        }

        cachedReels.insert(newReel, at: 0)
        return newReel
    }

    // MARK: - Like / Unlike

    func likeReel(id: String) async throws {
        let currentUserId = await resolveCurrentUserId()
        let updatePayload: [String: Any] = [
            "likesCount": FieldValue.increment(Int64(1)),
            "likedBy": FieldValue.arrayUnion([currentUserId])
        ]

        do {
            try await firestore.collection("reels").document(id).updateData(updatePayload)
        } catch {
            AppLogger.network.error("FirebaseReelDataSource.likeReel error: \(error.localizedDescription)")
        }

        if let idx = cachedReels.firstIndex(where: { $0.id == id }) {
            let reel = cachedReels[idx]
            cachedReels[idx] = reel.copy(likesCount: reel.likesCount + 1, isLiked: true)
        }
    }

    func unlikeReel(id: String) async throws {
        let currentUserId = await resolveCurrentUserId()
        let updatePayload: [String: Any] = [
            "likesCount": FieldValue.increment(Int64(-1)),
            "likedBy": FieldValue.arrayRemove([currentUserId])
        ]

        do {
            try await firestore.collection("reels").document(id).updateData(updatePayload)
        } catch {
            AppLogger.network.error("FirebaseReelDataSource.unlikeReel error: \(error.localizedDescription)")
        }

        if let idx = cachedReels.firstIndex(where: { $0.id == id }) {
            let reel = cachedReels[idx]
            cachedReels[idx] = reel.copy(likesCount: max(0, reel.likesCount - 1), isLiked: false)
        }
    }

    // MARK: - Save / Unsave

    func saveReel(id: String) async throws {
        let currentUserId = await resolveCurrentUserId()
        let updatePayload: [String: Any] = [
            "savedBy": FieldValue.arrayUnion([currentUserId])
        ]

        do {
            try await firestore.collection("reels").document(id).updateData(updatePayload)
        } catch {
            AppLogger.network.error("FirebaseReelDataSource.saveReel error: \(error.localizedDescription)")
        }

        if let idx = cachedReels.firstIndex(where: { $0.id == id }) {
            cachedReels[idx] = cachedReels[idx].copy(isSaved: true)
        }
    }

    func unsaveReel(id: String) async throws {
        let currentUserId = await resolveCurrentUserId()
        let updatePayload: [String: Any] = [
            "savedBy": FieldValue.arrayRemove([currentUserId])
        ]

        do {
            try await firestore.collection("reels").document(id).updateData(updatePayload)
        } catch {
            AppLogger.network.error("FirebaseReelDataSource.unsaveReel error: \(error.localizedDescription)")
        }

        if let idx = cachedReels.firstIndex(where: { $0.id == id }) {
            cachedReels[idx] = cachedReels[idx].copy(isSaved: false)
        }
    }

    // MARK: - Delete

    func deleteReel(id: String) async throws {
        do {
            try await firestore.collection("reels").document(id).delete()
        } catch {
            AppLogger.network.error("FirebaseReelDataSource.deleteReel error: \(error.localizedDescription)")
        }
        cachedReels.removeAll { $0.id == id }
    }

    // MARK: - Private Parsing & Mapping

    private func mergeCachedReels(_ newReels: [Reel]) {
        for reel in newReels {
            if let idx = cachedReels.firstIndex(where: { $0.id == reel.id }) {
                cachedReels[idx] = reel
            } else {
                cachedReels.append(reel)
            }
        }
    }

    private func parseReel(_ data: [String: Any], documentId: String, currentUserId: String) -> Reel? {
        let authorData = data["author"] as? [String: Any]
        let author = parseUser(authorData, rootData: data, fallbackId: data["authorId"] as? String ?? "")
        let videoUrlStr = data["videoUrl"] as? String ?? data["videoURL"] as? String ?? ""
        guard let videoURL = URL(string: videoUrlStr), !videoUrlStr.isEmpty else { return nil }

        let fallbackURL = (data["fallbackVideoUrl"] as? String ?? data["fallbackVideoURL"] as? String).flatMap { URL(string: $0) }
        let thumbURL = (data["thumbnailUrl"] as? String ?? data["thumbnailURL"] as? String).flatMap { URL(string: $0) }
        let caption = data["caption"] as? String

        let audioTrack: AudioTrack?
        if let audioData = data["audioTrack"] as? [String: Any] {
            audioTrack = AudioTrack(
                id: audioData["id"] as? String ?? documentId,
                name: audioData["name"] as? String ?? "Original Audio",
                artistName: audioData["artistName"] as? String ?? author.username,
                coverURL: (audioData["coverUrl"] as? String ?? audioData["coverURL"] as? String).flatMap { URL(string: $0) },
                isOriginal: audioData["isOriginal"] as? Bool ?? true
            )
        } else if let audioTitle = data["audioTitle"] as? String ?? (data["audioTrack"] as? String) {
            audioTrack = AudioTrack(
                id: "audio_\(documentId)",
                name: audioTitle,
                artistName: (data["audioArtist"] as? String) ?? author.username,
                coverURL: author.avatarURL,
                isOriginal: true
            )
        } else {
            audioTrack = nil
        }

        let likesCount = data["likesCount"] as? Int ?? 0
        let commentsCount = data["commentsCount"] as? Int ?? 0
        let sharesCount = data["sharesCount"] as? Int ?? 0
        let viewsCount = data["viewsCount"] as? Int ?? 0
        let duration = data["duration"] as? Double ?? 15.0
        let createdAt = parseDate(data["createdAt"])
        let likedBy = data["likedBy"] as? [String] ?? []
        let savedBy = data["savedBy"] as? [String] ?? []

        let isLiked = likedBy.contains(currentUserId)
        let isSaved = savedBy.contains(currentUserId)

        return Reel(
            id: documentId,
            author: author,
            videoURL: videoURL,
            fallbackVideoURL: fallbackURL,
            thumbnailURL: thumbURL,
            caption: caption,
            audioTrack: audioTrack,
            likesCount: max(0, likesCount),
            commentsCount: max(0, commentsCount),
            sharesCount: max(0, sharesCount),
            viewsCount: max(0, viewsCount),
            duration: duration,
            isLiked: isLiked,
            isSaved: isSaved,
            createdAt: createdAt
        )
    }

    private func reelToDict(_ reel: Reel) -> [String: Any] {
        var dict: [String: Any] = [
            "id": reel.id,
            "authorId": reel.author.id,
            "author": userToDict(reel.author),
            "videoUrl": reel.videoURL.absoluteString,
            "likesCount": reel.likesCount,
            "commentsCount": reel.commentsCount,
            "sharesCount": reel.sharesCount,
            "viewsCount": reel.viewsCount,
            "duration": reel.duration,
            "createdAt": Timestamp(date: reel.createdAt),
            "likedBy": reel.isLiked ? [reel.author.id] : [],
            "savedBy": reel.isSaved ? [reel.author.id] : []
        ]
        if let fallback = reel.fallbackVideoURL?.absoluteString { dict["fallbackVideoUrl"] = fallback }
        if let thumb = reel.thumbnailURL?.absoluteString { dict["thumbnailUrl"] = thumb }
        if let caption = reel.caption { dict["caption"] = caption }
        if let audio = reel.audioTrack {
            var audioDict: [String: Any] = [
                "id": audio.id,
                "name": audio.name,
                "artistName": audio.artistName,
                "isOriginal": audio.isOriginal
            ]
            if let cover = audio.coverURL?.absoluteString { audioDict["coverUrl"] = cover }
            dict["audioTrack"] = audioDict
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
