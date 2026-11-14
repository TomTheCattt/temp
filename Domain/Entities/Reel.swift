//
//  Reel.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - Reel

nonisolated struct Reel: Identifiable, Hashable, Sendable {
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
    let savesCount: Int
    let viewsCount: Int
    let duration: String
    let durationSeconds: Double?
    let allowRemix: Bool
    let allowDownload: Bool
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
        savesCount: Int = 0,
        viewsCount: Int,
        duration: String,
        durationSeconds: Double? = nil,
        allowRemix: Bool = true,
        allowDownload: Bool = true,
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
        self.savesCount = savesCount
        self.viewsCount = viewsCount
        self.duration = duration
        self.durationSeconds = durationSeconds
        self.allowRemix = allowRemix
        self.allowDownload = allowDownload
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
            savesCount: savesCount,
            viewsCount: viewsCount,
            duration: duration,
            durationSeconds: durationSeconds,
            allowRemix: allowRemix,
            allowDownload: allowDownload,
            isLiked: isLiked,
            isSaved: isSaved,
            createdAt: createdAt
        )
    }

    /// Returns a copy overriding only the provided fields.
    nonisolated func copy(
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
            savesCount: savesCount,
            viewsCount: viewsCount,
            duration: duration,
            durationSeconds: durationSeconds,
            allowRemix: allowRemix,
            allowDownload: allowDownload,
            isLiked: isLiked ?? self.isLiked,
            isSaved: isSaved ?? self.isSaved,
            createdAt: createdAt
        )
    }
}

// MARK: - AudioTrack

nonisolated struct AudioTrack: Hashable, Sendable {
    let id: String
    let name: String
    let artistName: String
    let coverURL: URL?
    let isOriginal: Bool
}
