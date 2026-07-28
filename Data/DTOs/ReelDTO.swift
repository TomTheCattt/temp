//
//  ReelDTO.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - ReelDTO

/// API response model for Reel.
nonisolated struct ReelDTO: Decodable, Sendable {
    let id: String
    let author: UserDTO
    let videoUrl: String
    let thumbnailUrl: String?
    let caption: String?
    let audioTrack: AudioTrackDTO?
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let viewsCount: Int
    let duration: Double
    let isLiked: Bool
    let isSaved: Bool
    let createdAt: String
}

// MARK: - AudioTrackDTO

nonisolated struct AudioTrackDTO: Decodable, Sendable {
    let id: String
    let name: String
    let artistName: String
    let coverUrl: String?
    let isOriginal: Bool
}
