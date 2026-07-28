//
//  SDCachedPost.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation
import SwiftData

// MARK: - SDCachedPost

/// SwiftData model for caching Posts offline.
/// Stores minimal fields needed for offline feed display.
@Model
final class SDCachedPost {
    @Attribute(.unique) var id: String
    var authorId: String
    var authorUsername: String
    var authorAvatarURL: String?
    var authorIsVerified: Bool
    var caption: String?
    var firstMediaURL: String?
    var firstMediaThumbnailURL: String?
    var firstMediaType: String // "image" | "video"
    var mediaCount: Int
    var locationName: String?
    var likesCount: Int
    var commentsCount: Int
    var createdAt: Date
    var isLiked: Bool
    var isSaved: Bool
    var isSponsored: Bool

    /// When this cache entry was last updated.
    var cachedAt: Date

    /// Feed position for ordering.
    var feedIndex: Int

    init(
        id: String,
        authorId: String,
        authorUsername: String,
        authorAvatarURL: String? = nil,
        authorIsVerified: Bool = false,
        caption: String? = nil,
        firstMediaURL: String? = nil,
        firstMediaThumbnailURL: String? = nil,
        firstMediaType: String = "image",
        mediaCount: Int = 1,
        locationName: String? = nil,
        likesCount: Int = 0,
        commentsCount: Int = 0,
        createdAt: Date = .now,
        isLiked: Bool = false,
        isSaved: Bool = false,
        isSponsored: Bool = false,
        cachedAt: Date = .now,
        feedIndex: Int = 0
    ) {
        self.id = id
        self.authorId = authorId
        self.authorUsername = authorUsername
        self.authorAvatarURL = authorAvatarURL
        self.authorIsVerified = authorIsVerified
        self.caption = caption
        self.firstMediaURL = firstMediaURL
        self.firstMediaThumbnailURL = firstMediaThumbnailURL
        self.firstMediaType = firstMediaType
        self.mediaCount = mediaCount
        self.locationName = locationName
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.createdAt = createdAt
        self.isLiked = isLiked
        self.isSaved = isSaved
        self.isSponsored = isSponsored
        self.cachedAt = cachedAt
        self.feedIndex = feedIndex
    }
}

// MARK: - Entity Mapping

extension SDCachedPost {

    /// Convert domain entity to SwiftData model.
    convenience init(from post: Post, feedIndex: Int = 0) {
        let firstMedia = post.mediaItems.first
        self.init(
            id: post.id,
            authorId: post.author.id,
            authorUsername: post.author.username,
            authorAvatarURL: post.author.avatarURL?.absoluteString,
            authorIsVerified: post.author.isVerified,
            caption: post.caption,
            firstMediaURL: firstMedia?.url.absoluteString,
            firstMediaThumbnailURL: firstMedia?.thumbnailURL?.absoluteString,
            firstMediaType: firstMedia?.type.rawValue ?? "image",
            mediaCount: post.mediaItems.count,
            locationName: post.location?.name,
            likesCount: post.likesCount,
            commentsCount: post.commentsCount,
            createdAt: post.createdAt,
            isLiked: post.isLiked,
            isSaved: post.isSaved,
            isSponsored: post.isSponsored,
            cachedAt: .now,
            feedIndex: feedIndex
        )
    }

    /// Convert SwiftData model back to domain entity.
    func toEntity() -> Post {
        let author = User(
            id: authorId,
            username: authorUsername,
            fullName: authorUsername,
            email: nil,
            phone: nil,
            avatarURL: authorAvatarURL.flatMap { URL(string: $0) },
            bio: nil,
            website: nil,
            isVerified: authorIsVerified,
            isPrivate: false,
            followersCount: 0,
            followingCount: 0,
            postsCount: 0,
            createdAt: .now,
            isFollowing: false,
            isFollowedBy: false,
            isBlocked: false
        )

        var mediaItems: [MediaItem] = []
        if let urlStr = firstMediaURL, let url = URL(string: urlStr) {
            mediaItems.append(MediaItem(
                id: "\(id)_media_0",
                url: url,
                thumbnailURL: firstMediaThumbnailURL.flatMap { URL(string: $0) },
                type: firstMediaType == "video" ? .video : .image,
                width: nil,
                height: nil,
                duration: nil
            ))
        }

        return Post(
            id: id,
            author: author,
            caption: caption,
            mediaItems: mediaItems,
            location: locationName.map { PostLocation(name: $0, latitude: nil, longitude: nil) },
            likesCount: likesCount,
            commentsCount: commentsCount,
            createdAt: createdAt,
            isLiked: isLiked,
            isSaved: isSaved,
            isSponsored: isSponsored
        )
    }
}
