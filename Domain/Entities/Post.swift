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
