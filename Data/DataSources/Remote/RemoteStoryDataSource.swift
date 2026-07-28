//
//  RemoteStoryDataSource.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation
import Alamofire

// MARK: - RemoteStoryDataSource

final class RemoteStoryDataSource: @unchecked Sendable {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func fetchStories() async throws -> [Story] {
        let dtos: [StoryDTO] = try await networkService.request(StoryEndpoint.feed)
        return StoryMapper.toEntityList(dtos)
    }

    func fetchStoryItems(userId: String) async throws -> [StoryItem] {
        let dto: StoryDTO = try await networkService.request(StoryEndpoint.userStory(userId: userId))
        return dto.items.map { item in
            StoryItem(
                id: item.id,
                mediaURL: URL(string: item.mediaUrl)!,
                type: item.type == "video" ? .video : .image,
                duration: item.duration,
                createdAt: DateMapper.toDate(item.createdAt),
                sticker: nil
            )
        }
    }

    func createStory(mediaData: Data, type: StoryItem.MediaType, duration: TimeInterval) async throws -> Story {
        let dto: StoryDTO = try await networkService.upload(StoryEndpoint.create) { formData in
            let mimeType = type == .video ? "video/mp4" : "image/jpeg"
            let fileName = type == .video ? "story.mp4" : "story.jpg"
            formData.append(mediaData, withName: "media", fileName: fileName, mimeType: mimeType)
            formData.append(Data("\(duration)".utf8), withName: "duration")
            formData.append(Data(type.rawValue.utf8), withName: "type")
        }
        return StoryMapper.toEntity(dto)
    }

    func markViewed(storyId: String) async throws {
        try await networkService.requestVoid(StoryEndpoint.markViewed(storyId: storyId))
    }

    func deleteStory(id: String) async throws {
        try await networkService.requestVoid(StoryEndpoint.delete(id: id))
    }
}
