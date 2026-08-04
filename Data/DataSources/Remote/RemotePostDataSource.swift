//
//  RemotePostDataSource.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation
import Alamofire

// MARK: - RemotePostDataSource

final class RemotePostDataSource: @unchecked Sendable {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    // MARK: - Feed

    func fetchFeed(page: Int, perPage: Int) async throws -> [Post] {
        let response: PaginatedPostsDTO = try await networkService.requestEnvelope(
            PostEndpoint.feed(page: page, perPage: perPage)
        )
        return PostMapper.toEntityList(response.items)
    }

    // MARK: - Explore

    func fetchExplorePosts(page: Int, perPage: Int) async throws -> [Post] {
        let response: PaginatedPostsDTO = try await networkService.requestEnvelope(
            PostEndpoint.explore(page: page, perPage: perPage)
        )
        return PostMapper.toEntityList(response.items)
    }

    // MARK: - Saved

    func fetchSavedPosts(page: Int, perPage: Int) async throws -> [Post] {
        let response: PaginatedPostsDTO = try await networkService.requestEnvelope(
            PostEndpoint.savedPosts(page: page, perPage: perPage)
        )
        return PostMapper.toEntityList(response.items)
    }

    // MARK: - User Posts

    func fetchUserPosts(userId: String, page: Int, perPage: Int) async throws -> [Post] {
        let response: PaginatedPostsDTO = try await networkService.requestEnvelope(
            PostEndpoint.userPosts(userId: userId, page: page, perPage: perPage)
        )
        return PostMapper.toEntityList(response.items)
    }

    // MARK: - Detail

    func fetchPost(id: String) async throws -> Post {
        let wrapper: PostWrapperDTO = try await networkService.requestEnvelope(
            PostEndpoint.detail(id: id)
        )
        return PostMapper.toEntity(wrapper.post)
    }

    // MARK: - Create

    func createPost(caption: String?, mediaData: [Data], location: PostLocation?) async throws -> Post {
        // Step 1: Upload media files
        var mediaItems: [[String: Any]] = []
        for data in mediaData {
            let uploadResponse: UploadImageResponseDTO = try await networkService.upload(
                UploadEndpoint.image
            ) { formData in
                formData.append(data, withName: "file", fileName: "image.jpg", mimeType: "image/jpeg")
            }
            var item: [String: Any] = [
                "url": uploadResponse.url,
                "type": "IMAGE"
            ]
            if let width = uploadResponse.width { item["width"] = width }
            if let height = uploadResponse.height { item["height"] = height }
            if let pendingId = uploadResponse.pendingUploadId { item["pendingUploadId"] = pendingId }
            mediaItems.append(item)
        }

        // Step 2: Create post with uploaded media URLs
        let wrapper: PostWrapperDTO = try await networkService.requestEnvelope(
            PostEndpoint.create(
                caption: caption,
                locationName: location?.name,
                locationLat: location?.latitude,
                locationLng: location?.longitude,
                media: mediaItems
            )
        )
        return PostMapper.toEntity(wrapper.post)
    }

    // MARK: - Actions

    func likePost(id: String) async throws {
        try await networkService.requestVoid(PostEndpoint.like(id: id))
    }

    func unlikePost(id: String) async throws {
        try await networkService.requestVoid(PostEndpoint.unlike(id: id))
    }

    func savePost(id: String) async throws {
        try await networkService.requestVoid(PostEndpoint.save(id: id))
    }

    func unsavePost(id: String) async throws {
        try await networkService.requestVoid(PostEndpoint.unsave(id: id))
    }

    func deletePost(id: String) async throws {
        try await networkService.requestVoid(PostEndpoint.delete(id: id))
    }
}
