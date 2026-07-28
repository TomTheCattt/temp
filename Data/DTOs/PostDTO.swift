//
//  PostDTO.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - PostDTO

/// API response model for Post.
nonisolated struct PostDTO: Decodable, Sendable {
    let id: String
    let author: UserDTO
    let caption: String?
    let mediaItems: [MediaItemDTO]
    let location: PostLocationDTO?
    let likesCount: Int
    let commentsCount: Int
    let createdAt: String
    let isLiked: Bool
    let isSaved: Bool
    let isSponsored: Bool
}

// MARK: - MediaItemDTO

nonisolated struct MediaItemDTO: Decodable, Sendable {
    let id: String
    let url: String
    let thumbnailUrl: String?
    let type: String // "image" | "video"
    let width: Int?
    let height: Int?
    let duration: Double?
}

// MARK: - PostLocationDTO

nonisolated struct PostLocationDTO: Decodable, Sendable {
    let name: String
    let latitude: Double?
    let longitude: Double?
}
