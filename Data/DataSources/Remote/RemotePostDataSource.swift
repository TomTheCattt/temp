//
//  RemotePostDataSource.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - RemotePostDataSource

final class RemotePostDataSource: @unchecked Sendable {

    private let networkService: NetworkServiceProtocol
    private let uploadDataSource: RemoteUploadDataSource

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
        self.uploadDataSource = RemoteUploadDataSource(networkService: networkService)
    }

    // MARK: - Feed

    func fetchFeed(cursor: String? = nil, perPage: Int = 20) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool) {
        let response: PaginatedPostsDTO = try await networkService.requestEnvelope(
            PostEndpoint.feed(cursor: cursor, perPage: perPage)
        )
        return (PostMapper.toEntityList(response.items), response.nextCursor, response.hasMore)
    }

    // MARK: - Explore

    func fetchExplorePosts(cursor: String? = nil, perPage: Int = 20) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool) {
        let response: PaginatedPostsDTO = try await networkService.requestEnvelope(
            PostEndpoint.explore(cursor: cursor, perPage: perPage)
        )
        return (PostMapper.toEntityList(response.items), response.nextCursor, response.hasMore)
    }

    // MARK: - Saved

    func fetchSavedPosts(cursor: String? = nil, perPage: Int = 20) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool) {
        let response: PaginatedPostsDTO = try await networkService.requestEnvelope(
            PostEndpoint.savedPosts(cursor: cursor, perPage: perPage)
        )
        return (PostMapper.toEntityList(response.items), response.nextCursor, response.hasMore)
    }

    // MARK: - User Posts

    func fetchUserPosts(userId: String, cursor: String? = nil, perPage: Int = 20) async throws -> (posts: [Post], nextCursor: String?, hasMore: Bool) {
        let response: PaginatedPostsDTO = try await networkService.requestEnvelope(
            PostEndpoint.userPosts(userId: userId, cursor: cursor, perPage: perPage)
        )
        return (PostMapper.toEntityList(response.items), response.nextCursor, response.hasMore)
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
        // Step 1: Upload media files using presigned URLs
        var mediaItems: [[String: Any]] = []
        for (_, data) in mediaData.enumerated() {
            if isVideoData(data) {
                let uploadResult = try await uploadDataSource.uploadPresigned(
                    data: data,
                    category: .video
                )
                var item: [String: Any] = [
                    "url": uploadResult.url,
                    "type": "VIDEO"
                ]
                if let width = uploadResult.width { item["width"] = width }
                if let height = uploadResult.height { item["height"] = height }
                if let duration = uploadResult.duration { item["duration"] = duration }
                if let pendingId = uploadResult.uploadId as String? { item["pendingUploadId"] = pendingId }
                mediaItems.append(item)
            } else {
                let uploadResult = try await uploadDataSource.uploadPresigned(
                    data: data,
                    category: .image
                )
                var item: [String: Any] = [
                    "url": uploadResult.url,
                    "type": "IMAGE"
                ]
                if let width = uploadResult.width { item["width"] = width }
                if let height = uploadResult.height { item["height"] = height }
                if let pendingId = uploadResult.uploadId as String? { item["pendingUploadId"] = pendingId }
                mediaItems.append(item)
            }
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

    // MARK: - Update

    func updatePost(id: String, caption: String?, location: PostLocation?) async throws -> Post {
        let wrapper: PostWrapperDTO = try await networkService.requestEnvelope(
            PostEndpoint.update(
                id: id,
                caption: caption,
                locationName: location?.name,
                locationLat: location?.latitude,
                locationLng: location?.longitude
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

    // MARK: - Comments

    func fetchComments(postId: String, cursor: String? = nil, perPage: Int = 20) async throws -> [Comment] {
        let response: PaginatedCommentsDTO = try await networkService.requestEnvelope(
            PostEndpoint.comments(postId: postId, cursor: cursor, perPage: perPage)
        )
        return CommentMapper.toEntityList(response.items)
    }

    func addComment(postId: String, text: String, parentId: String?) async throws -> Comment {
        let wrapper: CommentWrapperDTO = try await networkService.requestEnvelope(
            PostEndpoint.addComment(postId: postId, text: text, parentId: parentId)
        )
        return CommentMapper.toEntity(wrapper.comment)
    }

    // MARK: - Private Helpers

    private func isVideoData(_ data: Data) -> Bool {
        guard data.count >= 12 else { return false }
        let boxTypeBytes = [UInt8](data[4..<8])
        if let boxType = String(bytes: boxTypeBytes, encoding: .ascii) {
            return boxType == "ftyp" || boxType == "moov" || boxType == "wide"
        }
        return false
    }
}