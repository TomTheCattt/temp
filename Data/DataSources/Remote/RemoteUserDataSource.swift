//
//  RemoteUserDataSource.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation
import Alamofire

// MARK: - RemoteUserDataSource

final class RemoteUserDataSource: @unchecked Sendable {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    // MARK: - Profile

    func fetchCurrentUser() async throws -> User {
        let dto: UserDTO = try await networkService.request(UserProfileEndpoint.me)
        return UserMapper.toEntity(dto)
    }

    func fetchUser(id: String) async throws -> User {
        let dto: UserDTO = try await networkService.request(UserProfileEndpoint.user(id: id))
        return UserMapper.toEntity(dto)
    }

    func updateProfile(name: String?, bio: String?, website: String?) async throws -> User {
        let dto: UserDTO = try await networkService.request(
            UserProfileEndpoint.updateProfile(name: name, bio: bio, website: website)
        )
        return UserMapper.toEntity(dto)
    }

    func updateAvatar(imageData: Data) async throws -> User {
        let dto: UserDTO = try await networkService.upload(UserProfileEndpoint.updateAvatar) { formData in
            formData.append(imageData, withName: "avatar", fileName: "avatar.jpg", mimeType: "image/jpeg")
        }
        return UserMapper.toEntity(dto)
    }

    // MARK: - Search

    func searchUsers(query: String, page: Int, perPage: Int) async throws -> [User] {
        let response: PaginatedResponseDTO<UserDTO> = try await networkService.request(
            UserProfileEndpoint.search(query: query, page: page, perPage: perPage)
        )
        return UserMapper.toEntityList(response.items)
    }

    // MARK: - Follow

    func follow(userId: String) async throws {
        try await networkService.requestVoid(UserProfileEndpoint.follow(userId: userId))
    }

    func unfollow(userId: String) async throws {
        try await networkService.requestVoid(UserProfileEndpoint.unfollow(userId: userId))
    }

    func block(userId: String) async throws {
        try await networkService.requestVoid(UserProfileEndpoint.block(userId: userId))
    }

    func unblock(userId: String) async throws {
        try await networkService.requestVoid(UserProfileEndpoint.unblock(userId: userId))
    }

    // MARK: - Lists

    func fetchFollowers(userId: String, page: Int, perPage: Int) async throws -> [User] {
        let response: PaginatedResponseDTO<UserDTO> = try await networkService.request(
            UserProfileEndpoint.followers(userId: userId, page: page, perPage: perPage)
        )
        return UserMapper.toEntityList(response.items)
    }

    func fetchFollowing(userId: String, page: Int, perPage: Int) async throws -> [User] {
        let response: PaginatedResponseDTO<UserDTO> = try await networkService.request(
            UserProfileEndpoint.following(userId: userId, page: page, perPage: perPage)
        )
        return UserMapper.toEntityList(response.items)
    }

    func fetchSuggested(page: Int, perPage: Int) async throws -> [User] {
        let response: PaginatedResponseDTO<UserDTO> = try await networkService.request(
            UserProfileEndpoint.suggested(page: page, perPage: perPage)
        )
        return UserMapper.toEntityList(response.items)
    }
}
