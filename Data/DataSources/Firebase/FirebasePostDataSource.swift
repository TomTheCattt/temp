//
//  FirebasePostDataSource.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - FirebasePostDataSource

actor FirebasePostDataSource: Sendable {

    private let firestore: Firestore
    private let storageService: FirebaseStorageServiceProtocol
    private var cachedPosts: [Post] = []
    private var isCacheSeeded: Bool = false

    init(
        firestore: Firestore = Firestore.firestore(),
        storageService: FirebaseStorageServiceProtocol = FirebaseStorageService.shared
    ) {
        self.firestore = firestore
        self.storageService = storageService
    }

    // MARK: - Feed

    func fetchFeed(page: Int, perPage: Int) async throws -> [Post] {
        let currentUserId = await resolveCurrentUserId()

        do {
            let snapshot = try await firestore.collection("posts")
                .order(by: "createdAt", descending: true)
                .limit(to: perPage * page)
                .getDocuments()

            if !snapshot.documents.isEmpty {
                let posts = snapshot.documents.compactMap { doc -> Post? in
                    parsePost(doc.data(), documentId: doc.documentID, currentUserId: currentUserId)
                }
                mergeCachedPosts(posts)
            }
        } catch {
            AppLogger.network.error("FirebasePostDataSource.fetchFeed error: \(error.localizedDescription). Falling back to in-memory cache.")
        }

        let start = (page - 1) * perPage
        let end = min(start + perPage, cachedPosts.count)
        guard start < end else { return [] }
        return Array(cachedPosts[start..<end])
    }

    func fetchUserPosts(userId: String, page: Int, perPage: Int) async throws -> [Post] {
        let currentUserId = await resolveCurrentUserId()
        let isCurrent = (userId == currentUserId)
        let effectiveUserId = isCurrent ? currentUserId : userId

        do {
            let snapshot = try await firestore.collection("posts")
                .whereField("authorId", isEqualTo: effectiveUserId)
                .order(by: "createdAt", descending: true)
                .limit(to: perPage * page)
                .getDocuments()

            if !snapshot.documents.isEmpty {
                let posts = snapshot.documents.compactMap { doc -> Post? in
                    parsePost(doc.data(), documentId: doc.documentID, currentUserId: currentUserId)
                }
                mergeCachedPosts(posts)
            }
        } catch {
            AppLogger.network.error("FirebasePostDataSource.fetchUserPosts error: \(error.localizedDescription). Falling back to in-memory cache.")
        }

        let filtered = isCurrent
            ? cachedPosts.filter { $0.author.id == currentUserId }
            : cachedPosts.filter { $0.author.id == userId }

        let start = (page - 1) * perPage
        let end = min(start + perPage, filtered.count)
        guard start < end else { return [] }
        return Array(filtered[start..<end])
    }

    func fetchPost(id: String) async throws -> Post {
        let currentUserId = await resolveCurrentUserId()

        if let cached = cachedPosts.first(where: { $0.id == id }) {
            return cached
        }

        do {
            let doc = try await firestore.collection("posts").document(id).getDocument()
            if let data = doc.data(), let post = parsePost(data, documentId: doc.documentID, currentUserId: currentUserId) {
                mergeCachedPosts([post])
                return post
            }
        } catch {
            AppLogger.network.error("FirebasePostDataSource.fetchPost error: \(error.localizedDescription)")
        }

        if let fallback = cachedPosts.first(where: { $0.id == id }) {
            return fallback
        }
        throw APIError.notFound
    }

    // MARK: - Create

    func createPost(caption: String?, mediaData: [Data], location: PostLocation?) async throws -> Post {
        let currentUser = await resolveCurrentUser()
        let postId = "post_\(UUID().uuidString.prefix(10))"

        var mediaItems: [MediaItem] = []

        if mediaData.isEmpty {
            mediaItems.append(
                MediaItem(
                    id: "media_\(UUID().uuidString.prefix(8))",
                    url: URL(string: "https://picsum.photos/seed/\(postId)/1080/1080")!,
                    thumbnailURL: nil,
                    type: .image,
                    width: 1080,
                    height: 1080,
                    duration: nil
                )
            )
        } else {
            for (index, data) in mediaData.enumerated() {
                let isVideo = isVideoData(data)
                let mediaId = "media_\(postId)_\(index)"
                if isVideo {
                    let path = "posts/\(postId)/video_\(index).mp4"
                    let videoURL = try await storageService.uploadVideo(data: data, path: path)
                    mediaItems.append(
                        MediaItem(
                            id: mediaId,
                            url: videoURL,
                            thumbnailURL: nil,
                            type: .video,
                            width: 1080,
                            height: 1080,
                            duration: 15.0
                        )
                    )
                } else {
                    let path = "posts/\(postId)/image_\(index).jpg"
                    let imageURL = try await storageService.uploadImage(data: data, path: path)
                    mediaItems.append(
                        MediaItem(
                            id: mediaId,
                            url: imageURL,
                            thumbnailURL: nil,
                            type: .image,
                            width: 1080,
                            height: 1080,
                            duration: nil
                        )
                    )
                }
            }
        }

        let newPost = Post(
            id: postId,
            author: currentUser,
            caption: caption,
            mediaItems: mediaItems,
            location: location,
            likesCount: 0,
            commentsCount: 0,
            createdAt: .now,
            isLiked: false,
            isSaved: false,
            isSponsored: false
        )

        let postData = postToDict(newPost)
        do {
            try await firestore.collection("posts").document(postId).setData(postData)
        } catch {
            AppLogger.network.error("FirebasePostDataSource.createPost Firestore error: \(error.localizedDescription). Persisting in memory.")
        }

        cachedPosts.insert(newPost, at: 0)
        return newPost
    }

    // MARK: - Update

    func updatePost(id: String, caption: String?, location: PostLocation?) async throws -> Post {
        var updatePayload: [String: Any] = [
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let caption {
            updatePayload["caption"] = caption
        }
        if let location {
            updatePayload["location"] = locationToDict(location) as Any
        }

        do {
            try await firestore.collection("posts").document(id).updateData(updatePayload)
        } catch {
            AppLogger.network.error("FirebasePostDataSource.updatePost error: \(error.localizedDescription)")
        }

        if let idx = cachedPosts.firstIndex(where: { $0.id == id }) {
            let existing = cachedPosts[idx]
            let updated = Post(
                id: existing.id,
                author: existing.author,
                caption: caption ?? existing.caption,
                mediaItems: existing.mediaItems,
                location: location ?? existing.location,
                likesCount: existing.likesCount,
                commentsCount: existing.commentsCount,
                createdAt: existing.createdAt,
                isLiked: existing.isLiked,
                isSaved: existing.isSaved,
                isSponsored: existing.isSponsored
            )
            cachedPosts[idx] = updated
            return updated
        }

        return try await fetchPost(id: id)
    }

    // MARK: - Delete

    func deletePost(id: String) async throws {
        do {
            try await firestore.collection("posts").document(id).delete()
        } catch {
            AppLogger.network.error("FirebasePostDataSource.deletePost error: \(error.localizedDescription)")
        }
        cachedPosts.removeAll { $0.id == id }
    }

    // MARK: - Like / Unlike

    func likePost(id: String) async throws {
        let currentUserId = await resolveCurrentUserId()
        let updatePayload: [String: Any] = [
            "likesCount": FieldValue.increment(Int64(1)),
            "likedBy": FieldValue.arrayUnion([currentUserId])
        ]

        do {
            try await firestore.collection("posts").document(id).updateData(updatePayload)
        } catch {
            AppLogger.network.error("FirebasePostDataSource.likePost error: \(error.localizedDescription)")
        }

        if let idx = cachedPosts.firstIndex(where: { $0.id == id }) {
            cachedPosts[idx] = cachedPosts[idx].withLike(true)
        }
    }

    func unlikePost(id: String) async throws {
        let currentUserId = await resolveCurrentUserId()
        let updatePayload: [String: Any] = [
            "likesCount": FieldValue.increment(Int64(-1)),
            "likedBy": FieldValue.arrayRemove([currentUserId])
        ]

        do {
            try await firestore.collection("posts").document(id).updateData(updatePayload)
        } catch {
            AppLogger.network.error("FirebasePostDataSource.unlikePost error: \(error.localizedDescription)")
        }

        if let idx = cachedPosts.firstIndex(where: { $0.id == id }) {
            cachedPosts[idx] = cachedPosts[idx].withLike(false)
        }
    }

    // MARK: - Save / Unsave

    func savePost(id: String) async throws {
        let currentUserId = await resolveCurrentUserId()
        let updatePayload: [String: Any] = [
            "savedBy": FieldValue.arrayUnion([currentUserId])
        ]

        do {
            try await firestore.collection("posts").document(id).updateData(updatePayload)
        } catch {
            AppLogger.network.error("FirebasePostDataSource.savePost error: \(error.localizedDescription)")
        }

        if let idx = cachedPosts.firstIndex(where: { $0.id == id }) {
            cachedPosts[idx] = cachedPosts[idx].withSaved(true)
        }
    }

    func unsavePost(id: String) async throws {
        let currentUserId = await resolveCurrentUserId()
        let updatePayload: [String: Any] = [
            "savedBy": FieldValue.arrayRemove([currentUserId])
        ]

        do {
            try await firestore.collection("posts").document(id).updateData(updatePayload)
        } catch {
            AppLogger.network.error("FirebasePostDataSource.unsavePost error: \(error.localizedDescription)")
        }

        if let idx = cachedPosts.firstIndex(where: { $0.id == id }) {
            cachedPosts[idx] = cachedPosts[idx].withSaved(false)
        }
    }

    // MARK: - Saved Posts

    func fetchSavedPosts(page: Int, perPage: Int) async throws -> [Post] {
        let currentUserId = await resolveCurrentUserId()

        do {
            let snapshot = try await firestore.collection("posts")
                .whereField("savedBy", arrayContains: currentUserId)
                .order(by: "createdAt", descending: true)
                .limit(to: perPage * page)
                .getDocuments()

            if !snapshot.documents.isEmpty {
                let posts = snapshot.documents.compactMap { doc -> Post? in
                    parsePost(doc.data(), documentId: doc.documentID, currentUserId: currentUserId)
                }
                mergeCachedPosts(posts)
            }
        } catch {
            AppLogger.network.error("FirebasePostDataSource.fetchSavedPosts error: \(error.localizedDescription)")
        }

        let saved = cachedPosts.filter { $0.isSaved }
        let start = (page - 1) * perPage
        let end = min(start + perPage, saved.count)
        guard start < end else { return [] }
        return Array(saved[start..<end])
    }

    // MARK: - Explore Posts

    func fetchExplorePosts(page: Int, perPage: Int) async throws -> [Post] {
        let currentUserId = await resolveCurrentUserId()

        do {
            let snapshot = try await firestore.collection("posts")
                .order(by: "likesCount", descending: true)
                .limit(to: perPage * page)
                .getDocuments()

            if !snapshot.documents.isEmpty {
                let posts = snapshot.documents.compactMap { doc -> Post? in
                    parsePost(doc.data(), documentId: doc.documentID, currentUserId: currentUserId)
                }
                mergeCachedPosts(posts)
            }
        } catch {
            AppLogger.network.error("FirebasePostDataSource.fetchExplorePosts error: \(error.localizedDescription)")
        }

        let start = (page - 1) * perPage
        let end = min(start + perPage, cachedPosts.count)
        guard start < end else { return [] }
        return Array(cachedPosts[start..<end])
    }

    // MARK: - Private Parsing & Mapping

    private func mergeCachedPosts(_ newPosts: [Post]) {
        for post in newPosts {
            if let idx = cachedPosts.firstIndex(where: { $0.id == post.id }) {
                cachedPosts[idx] = post
            } else {
                cachedPosts.append(post)
            }
        }
    }

    private func parsePost(_ data: [String: Any], documentId: String, currentUserId: String) -> Post? {
        let authorData = data["author"] as? [String: Any]
        let fallbackAuthor = parseFallbackUser(data: data, fallbackId: data["authorId"] as? String ?? "")
        let author = authorData != nil ? parseUser(authorData, fallbackId: data["authorId"] as? String ?? "") : fallbackAuthor
        let caption = data["caption"] as? String

        var mediaItems: [MediaItem] = []
        if let rawItems = data["mediaItems"] as? [[String: Any]], !rawItems.isEmpty {
            mediaItems = rawItems.map { parseMediaItem($0) }
        } else if let urls = data["mediaURLs"] as? [String] ?? data["mediaUrls"] as? [String], !urls.isEmpty {
            let isVideo = (data["mediaType"] as? String)?.lowercased() == "video"
            mediaItems = urls.enumerated().map { index, urlStr in
                MediaItem(
                    id: "\(documentId)_media_\(index)",
                    url: URL(string: urlStr) ?? URL(string: "about:blank")!,
                    thumbnailURL: nil,
                    type: isVideo ? .video : .image,
                    width: 1080,
                    height: 1080,
                    duration: isVideo ? 15.0 : nil
                )
            }
        } else if let singleUrl = data["mediaUrl"] as? String ?? data["mediaURL"] as? String, let url = URL(string: singleUrl) {
            let isVideo = (data["mediaType"] as? String)?.lowercased() == "video"
            mediaItems = [
                MediaItem(
                    id: "\(documentId)_media_0",
                    url: url,
                    thumbnailURL: nil,
                    type: isVideo ? .video : .image,
                    width: 1080,
                    height: 1080,
                    duration: isVideo ? 15.0 : nil
                )
            ]
        }

        let locationData = data["location"] as? [String: Any]
        let location = locationData != nil ? parseLocation(locationData) : (data["location"] as? PostLocation).map { PostLocation(name: $0.name, latitude: $0.latitude, longitude: $0.longitude) }
        let likesCount = data["likesCount"] as? Int ?? 0
        let commentsCount = data["commentsCount"] as? Int ?? 0
        let createdAt = parseDate(data["createdAt"])
        let likedBy = data["likedBy"] as? [String] ?? []
        let savedBy = data["savedBy"] as? [String] ?? []
        let isSponsored = data["isSponsored"] as? Bool ?? false

        let isLiked = likedBy.contains(currentUserId)
        let isSaved = savedBy.contains(currentUserId)

        return Post(
            id: documentId,
            author: author,
            caption: caption,
            mediaItems: mediaItems,
            location: location,
            likesCount: max(0, likesCount),
            commentsCount: max(0, commentsCount),
            createdAt: createdAt,
            isLiked: isLiked,
            isSaved: isSaved,
            isSponsored: isSponsored
        )
    }

    private func postToDict(_ post: Post) -> [String: Any] {
        var dict: [String: Any] = [
            "id": post.id,
            "authorId": post.author.id,
            "author": userToDict(post.author),
            "mediaItems": post.mediaItems.map { mediaItemToDict($0) },
            "likesCount": post.likesCount,
            "commentsCount": post.commentsCount,
            "createdAt": Timestamp(date: post.createdAt),
            "updatedAt": FieldValue.serverTimestamp(),
            "isSponsored": post.isSponsored,
            "likedBy": post.isLiked ? [post.author.id] : [],
            "savedBy": post.isSaved ? [post.author.id] : []
        ]
        if let caption = post.caption { dict["caption"] = caption }
        if let location = locationToDict(post.location) { dict["location"] = location }
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
        if let email = user.email { dict["email"] = email }
        if let phone = user.phone { dict["phone"] = phone }
        if let avatarURL = user.avatarURL?.absoluteString { dict["avatarUrl"] = avatarURL }
        if let bio = user.bio { dict["bio"] = bio }
        if let website = user.website { dict["website"] = website }
        return dict
    }

    private func parseFallbackUser(data: [String: Any], fallbackId: String) -> User {
        let username = (data["authorUsername"] as? String) ?? (data["username"] as? String) ?? "user"
        let avatarURL = (data["authorPhotoUrl"] as? String ?? data["avatarURL"] as? String).flatMap { URL(string: $0) }
        return User(
            id: fallbackId,
            username: username,
            fullName: username.capitalized,
            email: nil,
            phone: nil,
            avatarURL: avatarURL,
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

    private func mediaItemToDict(_ item: MediaItem) -> [String: Any] {
        var dict: [String: Any] = [
            "id": item.id,
            "url": item.url.absoluteString,
            "type": item.type == .video ? "VIDEO" : "IMAGE"
        ]
        if let thumb = item.thumbnailURL?.absoluteString { dict["thumbnailUrl"] = thumb }
        if let width = item.width { dict["width"] = width }
        if let height = item.height { dict["height"] = height }
        if let duration = item.duration { dict["duration"] = duration }
        return dict
    }

    private func parseMediaItem(_ dict: [String: Any]) -> MediaItem {
        let id = dict["id"] as? String ?? UUID().uuidString
        let urlStr = dict["url"] as? String ?? ""
        let url = URL(string: urlStr) ?? URL(string: "about:blank")!
        let thumbStr = dict["thumbnailUrl"] as? String
        let thumb = thumbStr.flatMap { URL(string: $0) }
        let typeStr = (dict["type"] as? String)?.uppercased() ?? "IMAGE"
        let type: MediaItem.MediaType = typeStr == "VIDEO" ? .video : .image
        let width = dict["width"] as? Int
        let height = dict["height"] as? Int
        let duration = dict["duration"] as? Double
        return MediaItem(
            id: id,
            url: url,
            thumbnailURL: thumb,
            type: type,
            width: width,
            height: height,
            duration: duration
        )
    }

    private func locationToDict(_ loc: PostLocation?) -> [String: Any]? {
        guard let loc else { return nil }
        var dict: [String: Any] = ["name": loc.name]
        if let lat = loc.latitude { dict["latitude"] = lat }
        if let lng = loc.longitude { dict["longitude"] = lng }
        return dict
    }

    private func parseLocation(_ dict: [String: Any]?) -> PostLocation? {
        guard let dict, let name = dict["name"] as? String else { return nil }
        let lat = dict["latitude"] as? Double
        let lng = dict["longitude"] as? Double
        return PostLocation(name: name, latitude: lat, longitude: lng)
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

    private func isVideoData(_ data: Data) -> Bool {
        guard data.count >= 12 else { return false }
        let boxTypeBytes = [UInt8](data[4..<8])
        if let boxType = String(bytes: boxTypeBytes, encoding: .ascii) {
            return boxType == "ftyp" || boxType == "moov" || boxType == "wide"
        }
        return false
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
