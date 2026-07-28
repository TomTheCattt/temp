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
        let response: PaginatedResponseDTO<PostDTO> = try await networkService.request(
            PostEndpoint.feed(page: page, perPage: perPage)
        )
        return PostMapper.toEntityList(response.items)
    }

    // MARK: - User Posts

    func fetchUserPosts(userId: String, page: Int, perPage: Int) async throws -> [Post] {
        let response: PaginatedResponseDTO<PostDTO> = try await networkService.request(
            PostEndpoint.userPosts(userId: userId, page: page, perPage: perPage)
        )
        return PostMapper.toEntityList(response.items)
    }

    // MARK: - Detail

    func fetchPost(id: String) async throws -> Post {
        let dto: PostDTO = try await networkService.request(
            PostEndpoint.detail(id: id)
        )
        return PostMapper.toEntity(dto)
    }

    // MARK: - Create

    func createPost(caption: String?, mediaData: [Data], location: PostLocation?) async throws -> Post {
        let locationDict: [String: Any]? = location.map {
            var dict: [String: Any] = ["name": $0.name]
            if let lat = $0.latitude { dict["latitude"] = lat }
            if let lon = $0.longitude { dict["longitude"] = lon }
            return dict
        }

        let dto: PostDTO = try await networkService.upload(
            PostEndpoint.create(caption: caption, location: locationDict)
        ) { formData in
            for (index, data) in mediaData.enumerated() {
                formData.append(data, withName: "media[\(index)]", fileName: "media_\(index).jpg", mimeType: "image/jpeg")
            }
        }
        return PostMapper.toEntity(dto)
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

    // MARK: - Explore & Saved

    func fetchExplorePosts(page: Int, perPage: Int) async throws -> [Post] {
        let response: PaginatedResponseDTO<PostDTO> = try await networkService.request(
            PostEndpoint.explore(page: page, perPage: perPage)
        )
        return PostMapper.toEntityList(response.items)
    }

    func fetchSavedPosts(page: Int, perPage: Int) async throws -> [Post] {
        let response: PaginatedResponseDTO<PostDTO> = try await networkService.request(
            PostEndpoint.savedPosts(page: page, perPage: perPage)
        )
        return PostMapper.toEntityList(response.items)
    }
}
