//
//  FirebaseReelDataSource.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation

// MARK: - FirebaseReelDataSource

/// Skeletal actor for Firebase Reels.
/// Ready for rewriting logic from scratch.
actor FirebaseReelDataSource {

    static let shared = FirebaseReelDataSource()

    init() {}

    func fetchReels(cursor: String?, perPage: Int) async throws -> (reels: [Reel], nextCursor: String?, hasMore: Bool) {
        _ = cursor
        _ = perPage
        // TODO: Implement fetchReels logic from scratch
        return ([], nil, false)
    }

    func fetchUserReels(userId: String, cursor: String?, perPage: Int) async throws -> (reels: [Reel], nextCursor: String?, hasMore: Bool) {
        _ = userId
        _ = cursor
        _ = perPage
        // TODO: Implement fetchUserReels logic from scratch
        return ([], nil, false)
    }

    func createReel(videoData: Data, caption: String?, audioTrackId: String?) async throws -> Reel {
        _ = videoData
        _ = caption
        _ = audioTrackId
        // TODO: Implement createReel logic from scratch
        let myId = await SessionStore.shared.currentUserId
        let dummyUser = User(
            id: myId.isEmpty ? "user" : myId,
            username: "user",
            fullName: "User",
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
        return Reel(
            id: UUID().uuidString,
            author: dummyUser,
            videoURL: URL(string: "https://example.com/video.mp4")!,
            thumbnailURL: nil,
            caption: caption,
            audioTrack: nil,
            likesCount: 0,
            commentsCount: 0,
            sharesCount: 0,
            viewsCount: 0,
            duration: 15.0,
            isLiked: false,
            isSaved: false,
            createdAt: .now
        )
    }

    func likeReel(id: String) async throws {
        _ = id
        // TODO: Implement likeReel logic from scratch
    }

    func unlikeReel(id: String) async throws {
        _ = id
        // TODO: Implement unlikeReel logic from scratch
    }

    func saveReel(id: String) async throws {
        _ = id
        // TODO: Implement saveReel logic from scratch
    }

    func unsaveReel(id: String) async throws {
        _ = id
        // TODO: Implement unsaveReel logic from scratch
    }

    func deleteReel(id: String) async throws {
        _ = id
        // TODO: Implement deleteReel logic from scratch
    }
}
