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
            author: UserMapper.toEntity(dto.author),
            videoURL: URL(string: dto.videoUrl) ?? URL(string: "about:blank")!,
            thumbnailURL: dto.thumbnailUrl.flatMap { URL(string: $0) },
            caption: dto.caption,
            audioTrack: audioTrack,
            likesCount: dto.likesCount,
            commentsCount: dto.commentsCount,
            sharesCount: dto.sharesCount,
            viewsCount: dto.viewsCount,
            duration: dto.duration,
            isLiked: dto.isLiked ?? false,
            isSaved: false, // BE doesn't return isSaved for reels currently
            createdAt: DateMapper.toDate(dto.createdAt)
        )
    }

    static func toEntityList(_ dtos: [ReelDTO]) -> [Reel] {
        dtos.map { toEntity($0) }
    }
}
