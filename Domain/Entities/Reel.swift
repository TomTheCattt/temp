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
    let fallbackVideoURL: URL?
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

    init(
        id: String,
        author: User,
        videoURL: URL,
        fallbackVideoURL: URL? = nil,
        thumbnailURL: URL?,
        caption: String?,
        audioTrack: AudioTrack?,
        likesCount: Int,
        commentsCount: Int,
        sharesCount: Int,
        viewsCount: Int,
        duration: TimeInterval,
        isLiked: Bool,
        isSaved: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.author = author
        self.videoURL = videoURL
        self.fallbackVideoURL = fallbackVideoURL
        self.thumbnailURL = thumbnailURL
        self.caption = caption
        self.audioTrack = audioTrack
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.sharesCount = sharesCount
        self.viewsCount = viewsCount
        self.duration = duration
        self.isLiked = isLiked
        self.isSaved = isSaved
        self.createdAt = createdAt
    }
}

// MARK: - Optimistic Update Helpers

extension Reel {
    /// Returns a copy with like state toggled and the count adjusted.
    func togglingLike() -> Reel {
        let newLiked = !isLiked
        return copy(
            likesCount: max(0, likesCount + (newLiked ? 1 : -1)),
            isLiked: newLiked
        )
    }

    /// Returns a copy with save state toggled.
    func togglingSave() -> Reel {
        copy(isSaved: !isSaved)
    }

    /// Returns a copy with a replaced author (e.g. after a follow-state change).
    func withAuthor(_ newAuthor: User) -> Reel {
        Reel(
            id: id,
            author: newAuthor,
            videoURL: videoURL,
            fallbackVideoURL: fallbackVideoURL,
            thumbnailURL: thumbnailURL,
            caption: caption,
            audioTrack: audioTrack,
            likesCount: likesCount,
            commentsCount: commentsCount,
            sharesCount: sharesCount,
            viewsCount: viewsCount,
            duration: duration,
            isLiked: isLiked,
            isSaved: isSaved,
            createdAt: createdAt
        )
    }

    /// Returns a copy overriding only the provided fields.
    func copy(
        likesCount: Int? = nil,
        isLiked: Bool? = nil,
        isSaved: Bool? = nil
    ) -> Reel {
        Reel(
            id: id,
            author: author,
            videoURL: videoURL,
            fallbackVideoURL: fallbackVideoURL,
            thumbnailURL: thumbnailURL,
            caption: caption,
            audioTrack: audioTrack,
            likesCount: likesCount ?? self.likesCount,
            commentsCount: commentsCount,
            sharesCount: sharesCount,
            viewsCount: viewsCount,
            duration: duration,
            isLiked: isLiked ?? self.isLiked,
            isSaved: isSaved ?? self.isSaved,
            createdAt: createdAt
        )
    }
}

// MARK: - AudioTrack

struct AudioTrack: Hashable, Sendable {
    let id: String
    let name: String
    let artistName: String
    let coverURL: URL?
    let isOriginal: Bool
}
