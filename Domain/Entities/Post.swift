//
//  Post.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - Post

nonisolated struct Post: Identifiable, Hashable, Sendable {
    let id: String
    let author: User
    let caption: String?
    let mediaItems: [MediaItem]
    let location: PostLocation?
    let likesCount: Int
    let commentsCount: Int
    let savesCount: Int
    let viewsCount: Int
    let audience: PostAudience?
    let closeFriendsOnly: Bool
    let createdAt: Date
    let updatedAt: Date?
    let isLiked: Bool
    let isSaved: Bool
    let isSponsored: Bool

    init(
        id: String,
        author: User,
        caption: String?,
        mediaItems: [MediaItem],
        location: PostLocation?,
        likesCount: Int,
        commentsCount: Int,
        savesCount: Int = 0,
        viewsCount: Int = 0,
        audience: PostAudience? = nil,
        closeFriendsOnly: Bool = false,
        createdAt: Date,
        updatedAt: Date? = nil,
        isLiked: Bool,
        isSaved: Bool,
        isSponsored: Bool = false
    ) {
        self.id = id
        self.author = author
        self.caption = caption
        self.mediaItems = mediaItems
        self.location = location
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.savesCount = savesCount
        self.viewsCount = viewsCount
        self.audience = audience
        self.closeFriendsOnly = closeFriendsOnly
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isLiked = isLiked
        self.isSaved = isSaved
        self.isSponsored = isSponsored
    }
}

// MARK: - Post + Optimistic Update Helpers

extension Post {

    /// Returns a copy with the like state toggled and `likesCount` adjusted accordingly.
    nonisolated func withLike(_ liked: Bool) -> Post {
        Post(
            id: id,
            author: author,
            caption: caption,
            mediaItems: mediaItems,
            location: location,
            likesCount: likesCount + (liked ? 1 : -1),
            commentsCount: commentsCount,
            savesCount: savesCount,
            viewsCount: viewsCount,
            audience: audience,
            closeFriendsOnly: closeFriendsOnly,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isLiked: liked,
            isSaved: isSaved,
            isSponsored: isSponsored
        )
    }

    /// Returns a copy with the saved (bookmark) state changed.
    nonisolated func withSaved(_ saved: Bool) -> Post {
        Post(
            id: id,
            author: author,
            caption: caption,
            mediaItems: mediaItems,
            location: location,
            likesCount: likesCount,
            commentsCount: commentsCount,
            savesCount: savesCount + (saved ? 1 : -1),
            viewsCount: viewsCount,
            audience: audience,
            closeFriendsOnly: closeFriendsOnly,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isLiked: isLiked,
            isSaved: saved,
            isSponsored: isSponsored
        )
    }
}

// MARK: - MediaItem

nonisolated struct MediaItem: Identifiable, Hashable, Sendable {
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

nonisolated struct PostLocation: Hashable, Sendable {
    let name: String
    let latitude: Double?
    let longitude: Double?
}
