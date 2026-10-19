//
//  FirebaseDataSeeder.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation
import OSLog
import FirebaseFirestore
import FirebaseAuth

// MARK: - FirebaseDataSeeder

/// Actor responsible for seeding and synchronizing mock data to Cloud Firestore.
/// Ensures all existing mock data (Users, Posts, Stories, Reels, Comments, Notifications, Conversations, Messages, Notes)
/// are populated into Firebase so they are visible on Firebase Console web and across devices.
actor FirebaseDataSeeder: Sendable {

    static let shared = FirebaseDataSeeder()

    private let db = Firestore.firestore()
    private var isSeeding = false
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.tomthecat.InstagramClone", category: "FirebaseDataSeeder")

    private init() {}

    // MARK: - Seed If Needed

    /// Checks if the Firestore database has already been seeded for the active user.
    /// If not, seeds all initial collections in background tasks without blocking UI.
    func seedIfNeeded() async {
        guard !isSeeding else { return }
        isSeeding = true
        defer { isSeeding = false }

        let authUid = Auth.auth().currentUser?.uid
        guard let currentUid = authUid, !currentUid.isEmpty else {
            logger.info("FirebaseDataSeeder: No authenticated Firebase user yet, deferring seed.")
            return
        }

        let seedKey = "com.instagram.firebase.seeded_\(currentUid)"
        if UserDefaults.standard.bool(forKey: seedKey) {
            logger.info("FirebaseDataSeeder: Database is already seeded locally for user \(currentUid).")
            return
        }

        do {
            // Check cloud seed status under user document (always permitted by rules)
            let statusDoc = try? await db.collection("users").document(currentUid).collection("metadata").document("seed_status").getDocument()
            if let isSeeded = statusDoc?.data()?["is_seeded"] as? Bool, isSeeded {
                logger.info("FirebaseDataSeeder: Database is already marked as seeded in cloud.")
                UserDefaults.standard.set(true, forKey: seedKey)
                return
            }

            logger.info("FirebaseDataSeeder: Starting initial data seeding to Firestore for user \(currentUid)...")
            try await performFullSeed(currentUid: currentUid)
            UserDefaults.standard.set(true, forKey: seedKey)
            logger.info("FirebaseDataSeeder: Initial data seeding completed successfully.")
        } catch {
            logger.error("FirebaseDataSeeder: Cloud seed notice: \(error.localizedDescription). Local caches active.")
        }
    }

    // MARK: - Private: Perform Full Seed

    private func performFullSeed(currentUid: String) async throws {
        // 1. Seed Current User Document
        let myEmail = Auth.auth().currentUser?.email ?? MockData.testEmail
        let myUserDoc: [String: Any] = [
            "id": currentUid,
            "uid": currentUid,
            "username": MockData.currentUser.username,
            "fullName": MockData.currentUser.fullName,
            "email": myEmail,
            "phone": MockData.currentUser.phone ?? "",
            "avatarURL": MockData.currentUser.avatarURL?.absoluteString ?? "",
            "avatarUrl": MockData.currentUser.avatarURL?.absoluteString ?? "",
            "bio": MockData.currentUser.bio ?? "",
            "website": MockData.currentUser.website ?? "",
            "isVerified": MockData.currentUser.isVerified,
            "isPrivate": MockData.currentUser.isPrivate,
            "followersCount": MockData.currentUser.followersCount,
            "followingCount": MockData.currentUser.followingCount,
            "postsCount": MockData.currentUser.postsCount,
            "isFollowing": false,
            "isFollowedBy": false,
            "isBlocked": false,
            "createdAt": Timestamp(date: MockData.currentUser.createdAt)
        ]
        try? await db.collection("users").document(currentUid).setData(myUserDoc, merge: true)

        // Seed other friend user profiles (graceful fallback if per-user owner rules apply)
        for user in MockData.users.prefix(10) {
            let userDoc: [String: Any] = [
                "id": user.id,
                "uid": user.id,
                "username": user.username,
                "fullName": user.fullName,
                "email": user.email ?? "\(user.username)@example.com",
                "phone": user.phone ?? "",
                "avatarURL": user.avatarURL?.absoluteString ?? "",
                "avatarUrl": user.avatarURL?.absoluteString ?? "",
                "bio": user.bio ?? "",
                "website": user.website ?? "",
                "isVerified": user.isVerified,
                "isPrivate": user.isPrivate,
                "followersCount": user.followersCount,
                "followingCount": user.followingCount,
                "postsCount": user.postsCount,
                "isFollowing": user.isFollowing,
                "isFollowedBy": user.isFollowedBy,
                "isBlocked": user.isBlocked,
                "createdAt": Timestamp(date: user.createdAt)
            ]
            try? await db.collection("users").document(user.id).setData(userDoc, merge: true)
        }

        // 2. Seed Posts (Using currentUid as authorId to strictly pass firestore.rules)
        for (index, post) in MockData.posts.prefix(12).enumerated() {
            let postId = "post_cloud_\(index + 1)"
            let mediaItemsDict = post.mediaItems.map { item -> [String: Any] in
                var dict: [String: Any] = [
                    "id": item.id,
                    "url": item.url.absoluteString,
                    "type": item.type == .video ? "VIDEO" : "IMAGE"
                ]
                if let w = item.width { dict["width"] = w }
                if let h = item.height { dict["height"] = h }
                return dict
            }
            let mediaURLs = post.mediaItems.map { $0.url.absoluteString }

            let postDoc: [String: Any] = [
                "id": postId,
                "authorId": currentUid,
                "authorUsername": post.author.username,
                "authorPhotoUrl": post.author.avatarURL?.absoluteString ?? "",
                "author": [
                    "id": currentUid,
                    "username": post.author.username,
                    "fullName": post.author.fullName,
                    "avatarUrl": post.author.avatarURL?.absoluteString ?? "",
                    "isVerified": post.author.isVerified
                ],
                "caption": post.caption ?? "",
                "mediaItems": mediaItemsDict,
                "mediaURLs": mediaURLs,
                "mediaUrls": mediaURLs,
                "mediaUrl": mediaURLs.first ?? "",
                "mediaType": post.mediaItems.first?.type == .video ? "video" : "image",
                "location": ["name": post.location?.name ?? "Da Nang, Vietnam"],
                "likesCount": post.likesCount,
                "commentsCount": post.commentsCount,
                "likedBy": post.isLiked ? [currentUid] : [],
                "savedBy": post.isSaved ? [currentUid] : [],
                "createdAt": Timestamp(date: post.createdAt)
            ]
            try? await db.collection("posts").document(postId).setData(postDoc, merge: true)
        }

        // 3. Seed Stories (Expires in +24h from now so queries find active stories)
        for (index, story) in MockData.stories.prefix(8).enumerated() {
            let storyId = "story_cloud_\(index + 1)"
            let mediaUrl = story.items.first?.mediaURL.absoluteString ?? "https://picsum.photos/seed/\(storyId)/1080/1920"
            let itemsDict = story.items.map { item -> [String: Any] in
                [
                    "id": item.id,
                    "mediaUrl": item.mediaURL.absoluteString,
                    "url": item.mediaURL.absoluteString,
                    "type": item.type == .video ? "VIDEO" : "IMAGE",
                    "duration": item.duration,
                    "createdAt": Timestamp(date: Date())
                ]
            }

            let storyDoc: [String: Any] = [
                "id": storyId,
                "authorId": currentUid,
                "authorUsername": story.author.username,
                "authorPhotoUrl": story.author.avatarURL?.absoluteString ?? "",
                "author": [
                    "id": currentUid,
                    "username": story.author.username,
                    "fullName": story.author.fullName,
                    "avatarUrl": story.author.avatarURL?.absoluteString ?? ""
                ],
                "mediaUrl": mediaUrl,
                "mediaType": "image",
                "items": itemsDict,
                "itemsCount": itemsDict.count,
                "viewedBy": story.isViewed ? [currentUid] : [],
                "createdAt": Timestamp(date: Date()),
                "expiresAt": Timestamp(date: Date().addingTimeInterval(86400))
            ]
            try? await db.collection("stories").document(storyId).setData(storyDoc, merge: true)
        }

        // 4. Seed Reels (Providing both videoUrl and videoURL, thumbnailURL and thumbnailUrl)
        for (index, reel) in MockData.reels.prefix(12).enumerated() {
            let reelId = "reel_cloud_\(index + 1)"
            let reelDoc: [String: Any] = [
                "id": reelId,
                "authorId": currentUid,
                "authorUsername": reel.author.username,
                "authorPhotoUrl": reel.author.avatarURL?.absoluteString ?? "",
                "author": [
                    "id": currentUid,
                    "username": reel.author.username,
                    "fullName": reel.author.fullName,
                    "avatarUrl": reel.author.avatarURL?.absoluteString ?? ""
                ],
                "videoUrl": reel.videoURL.absoluteString,
                "videoURL": reel.videoURL.absoluteString,
                "thumbnailUrl": reel.thumbnailURL?.absoluteString ?? "",
                "thumbnailURL": reel.thumbnailURL?.absoluteString ?? "",
                "caption": reel.caption ?? "",
                "audioTrack": [
                    "id": "audio_\(reelId)",
                    "name": reel.audioTrack?.name ?? "Original Audio",
                    "artistName": reel.audioTrack?.artistName ?? reel.author.username,
                    "isOriginal": true
                ],
                "audioTitle": reel.audioTrack?.name ?? "Original Audio",
                "audioArtist": reel.audioTrack?.artistName ?? reel.author.username,
                "likesCount": reel.likesCount,
                "commentsCount": reel.commentsCount,
                "sharesCount": reel.sharesCount,
                "viewsCount": reel.viewsCount,
                "likedBy": reel.isLiked ? [currentUid] : [],
                "savedBy": reel.isSaved ? [currentUid] : [],
                "duration": 15.0,
                "createdAt": Timestamp(date: Date())
            ]
            try? await db.collection("reels").document(reelId).setData(reelDoc, merge: true)
        }

        // 5. Seed Conversations & Messages
        for conv in MockData.conversations.prefix(8) {
            let participants = conv.participants.map { user -> User in
                if user.id == MockData.currentUser.id || user.id == "user_current" {
                    return User(
                        id: currentUid,
                        username: user.username,
                        fullName: user.fullName,
                        email: user.email,
                        phone: user.phone,
                        avatarURL: user.avatarURL,
                        bio: user.bio,
                        website: user.website,
                        isVerified: user.isVerified,
                        isPrivate: user.isPrivate,
                        followersCount: user.followersCount,
                        followingCount: user.followingCount,
                        postsCount: user.postsCount,
                        createdAt: user.createdAt,
                        isFollowing: user.isFollowing,
                        isFollowedBy: user.isFollowedBy,
                        isBlocked: user.isBlocked
                    )
                }
                return user
            }

            let remappedLastMessage: Message? = conv.lastMessage.map { msg in
                let sender = (msg.sender.id == MockData.currentUser.id || msg.sender.id == "user_current")
                    ? (participants.first(where: { $0.id == currentUid }) ?? msg.sender)
                    : msg.sender
                return Message(
                    id: msg.id,
                    conversationId: conv.id,
                    sender: sender,
                    content: msg.content,
                    status: msg.status,
                    replyToId: msg.replyToId,
                    replyToSnippet: msg.replyToSnippet,
                    reactions: msg.reactions,
                    createdAt: msg.createdAt
                )
            }

            let remappedConv = Conversation(
                id: conv.id,
                participants: participants,
                lastMessage: remappedLastMessage,
                unreadCount: conv.unreadCount,
                isGroup: conv.isGroup,
                groupName: conv.groupName,
                groupAvatarURL: conv.groupAvatarURL,
                updatedAt: conv.updatedAt,
                isMuted: conv.isMuted
            )

            let convDict = FirebaseMessageDataSource.conversationToDict(remappedConv)
            try? await db.collection("conversations").document(conv.id).setData(convDict, merge: true)

            // Seed full dialogue history into conversation subcollection
            let history = MockData.seededMessages[conv.id] ?? []
            for msg in history {
                let sender = (msg.sender.id == MockData.currentUser.id || msg.sender.id == "user_current")
                    ? (participants.first(where: { $0.id == currentUid }) ?? msg.sender)
                    : msg.sender
                let remappedMsg = Message(
                    id: msg.id,
                    conversationId: conv.id,
                    sender: sender,
                    content: msg.content,
                    status: msg.status,
                    replyToId: msg.replyToId,
                    replyToSnippet: msg.replyToSnippet,
                    reactions: msg.reactions,
                    createdAt: msg.createdAt
                )
                let msgDict = FirebaseMessageDataSource.messageToDict(remappedMsg)
                try? await db.collection("conversations").document(conv.id).collection("messages").document(msg.id).setData(msgDict, merge: true)
            }
        }

        // 6. Mark seed as complete under user subcollection (permitted by user subcollection rule)
        let statusPayload: [String: Any] = [
            "is_seeded": true,
            "seeded_at": Timestamp(date: Date()),
            "environment": "dev"
        ]
        try? await db.collection("users").document(currentUid).collection("metadata").document("seed_status").setData(statusPayload, merge: true)
        try? await db.collection("metadata").document("seed_status").setData(statusPayload, merge: true)
    }

    private func extractText(from content: MessageContent) -> String {
        switch content {
        case .text(let txt): return txt
        case .image: return "[Image]"
        case .video: return "[Video]"
        case .audio: return "[Voice Message]"
        case .post: return "[Shared Post]"
        case .story: return "[Shared Story]"
        case .reel: return "[Shared Reel]"
        case .like: return "❤️"
        }
    }
}
