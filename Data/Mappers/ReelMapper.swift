//
//  ReelMapper.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - ReelMapper

nonisolated enum ReelMapper {

    static func toEntity(_ dto: ReelDTO) -> Reel {
        let audioTrack: AudioTrack?
        if let audioName = dto.audioName {
            audioTrack = AudioTrack(
                id: dto.id, // Use reel ID as audio track ID (BE doesn't provide separate audio ID)
                name: audioName,
                artistName: dto.audioArtist ?? "",
                coverURL: dto.audioCoverUrl.flatMap { URL(string: $0) },
                isOriginal: dto.isOriginalAudio ?? true
            )
        } else {
            audioTrack = nil
        }

        return Reel(
            id: dto.id,
            author: toAuthor(dto.author),
            videoURL: URL(string: dto.videoUrl) ?? URL(string: "about:blank")!,
            thumbnailURL: dto.thumbnailUrl.flatMap { URL(string: $0) },
            caption: dto.caption,
            audioTrack: audioTrack,
            likesCount: dto.likesCount ?? 0,
            commentsCount: dto.commentsCount ?? 0,
            sharesCount: dto.sharesCount ?? 0,
            viewsCount: dto.viewsCount ?? 0,
            duration: dto.duration ?? "0",
            isLiked: dto.isLiked ?? false,
            isSaved: dto.isSaved ?? false,
            createdAt: DateMapper.toDate(dto.createdAt)
        )
    }

    static func toEntityList(_ dtos: [ReelDTO]) -> [Reel] {
        dtos.map { toEntity($0) }
    }

    // MARK: - Author Mapping

    private static func toAuthor(_ dto: ReelAuthorDTO) -> User {
        User(
            id: dto.id,
            username: dto.username ?? "",
            fullName: dto.fullName ?? "",
            email: nil,
            phone: nil,
            avatarURL: dto.avatarUrl.flatMap { URL(string: $0) },
            bio: nil,
            website: nil,
            isVerified: dto.isVerified ?? false,
            isPrivate: false,
            followersCount: 0,
            followingCount: 0,
            postsCount: 0,
            createdAt: .now,
            isFollowing: dto.isFollowing ?? false,
            isFollowedBy: false,
            isBlocked: false
        )
    }
}
