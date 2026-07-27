//
//  Reel.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - Reel

struct Reel: Identifiable, Hashable, Sendable {
    let id: String
    let author: User
    let videoURL: URL
    let thumbnailURL: URL?
    let caption: String?
    let audioTrack: AudioTrack?
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let viewsCount: Int
    let duration: TimeInterval
    let isLiked: Bool
    let isSaved: Bool
    let createdAt: Date
}

// MARK: - AudioTrack

struct AudioTrack: Hashable, Sendable {
    let id: String
    let name: String
    let artistName: String
    let coverURL: URL?
    let isOriginal: Bool
}
