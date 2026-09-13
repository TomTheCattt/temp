//
//  Post.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - Post

struct Post: Identifiable, Hashable, Sendable {
    let id: String
    let author: User
    let caption: String?
    let mediaItems: [MediaItem]
    let location: PostLocation?
    let likesCount: Int
    let commentsCount: Int
    let createdAt: Date
    let isLiked: Bool
    let isSaved: Bool
    let isSponsored: Bool
}

// MARK: - Post + Optimistic Update Helpers

extension Post {

    /// Returns a copy with the like state toggled and `likesCount` adjusted accordingly.
    func withLike(_ liked: Bool) -> Post {
        Post(
            id: id,
            author: author,
            caption: caption,
            mediaItems: mediaItems,
            location: location,
            likesCount: likesCount + (liked ? 1 : -1),
            commentsCount: commentsCount,
            createdAt: createdAt,
            isLiked: liked,
            isSaved: isSaved,
            isSponsored: isSponsored
        )
    }

    /// Returns a copy with the saved (bookmark) state changed.
    func withSaved(_ saved: Bool) -> Post {
        Post(
            id: id,
            author: author,
            caption: caption,
            mediaItems: mediaItems,
            location: location,
            likesCount: likesCount,
            commentsCount: commentsCount,
            createdAt: createdAt,
            isLiked: isLiked,
            isSaved: saved,
            isSponsored: isSponsored
        )
    }
}

// MARK: - MediaItem

struct MediaItem: Identifiable, Hashable, Sendable {
    let id: String
    let url: URL
    let thumbnailURL: URL?
    let type: MediaType
    let width: Int?
    let height: Int?
    let duration: TimeInterval? // for video

    enum MediaType: String, Sendable, Hashable {
        case image
        case video
    }
}

// MARK: - PostLocation

struct PostLocation: Hashable, Sendable {
    let name: String
    let latitude: Double?
    let longitude: Double?
}
