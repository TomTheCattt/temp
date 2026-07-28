//
//  ReelMapper.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - ReelMapper

enum ReelMapper {

    static func toEntity(_ dto: ReelDTO) -> Reel {
        Reel(
            id: dto.id,
            author: UserMapper.toEntity(dto.author),
            videoURL: URL(string: dto.videoUrl)!,
            thumbnailURL: dto.thumbnailUrl.flatMap { URL(string: $0) },
            caption: dto.caption,
            audioTrack: dto.audioTrack.map { toAudioTrack($0) },
            likesCount: dto.likesCount,
            commentsCount: dto.commentsCount,
            sharesCount: dto.sharesCount,
            viewsCount: dto.viewsCount,
            duration: dto.duration,
            isLiked: dto.isLiked,
            isSaved: dto.isSaved,
            createdAt: DateMapper.toDate(dto.createdAt)
        )
    }

    static func toEntityList(_ dtos: [ReelDTO]) -> [Reel] {
        dtos.map { toEntity($0) }
    }

    // MARK: - AudioTrack

    private static func toAudioTrack(_ dto: AudioTrackDTO) -> AudioTrack {
        AudioTrack(
            id: dto.id,
            name: dto.name,
            artistName: dto.artistName,
            coverURL: dto.coverUrl.flatMap { URL(string: $0) },
            isOriginal: dto.isOriginal
        )
    }
}
