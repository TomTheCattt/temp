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
        let wrapper: UserWrapperDTO = try await networkService.requestEnvelope(
            UserProfileEndpoint.me
        )
        return UserMapper.toEntity(wrapper.user)
    }

    func fetchUser(id: String) async throws -> User {
        let wrapper: UserWrapperDTO = try await networkService.requestEnvelope(
            UserProfileEndpoint.user(id: id)
        )
        return UserMapper.toEntity(wrapper.user)
    }

    func updateProfile(name: String?, bio: String?, website: String?) async throws -> User {
        let wrapper: UserWrapperDTO = try await networkService.requestEnvelope(
            UserProfileEndpoint.updateProfile(fullName: name, bio: bio, website: website, isPrivate: nil)
        )
        return UserMapper.toEntity(wrapper.user)
    }

    func updateAvatar(imageData: Data) async throws -> User {
        let response: UploadAvatarResponseDTO = try await networkService.upload(
            UploadEndpoint.avatar
        ) { formData in
            formData.append(imageData, withName: "file", fileName: "avatar.jpg", mimeType: "image/jpeg")
        }
        // After upload, fetch updated user profile
        let wrapper: UserWrapperDTO = try await networkService.requestEnvelope(
            UserProfileEndpoint.me
        )
        return UserMapper.toEntity(wrapper.user)
    }

    // MARK: - Search

    func searchUsers(query: String, page: Int, perPage: Int) async throws -> [User] {
        let response: PaginatedUsersDTO = try await networkService.requestEnvelope(
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
        let response: PaginatedUsersDTO = try await networkService.requestEnvelope(
            UserProfileEndpoint.followers(userId: userId, page: page, perPage: perPage)
        )
        return UserMapper.toEntityList(response.items)
    }

    func fetchFollowing(userId: String, page: Int, perPage: Int) async throws -> [User] {
        let response: PaginatedUsersDTO = try await networkService.requestEnvelope(
            UserProfileEndpoint.following(userId: userId, page: page, perPage: perPage)
        )
        return UserMapper.toEntityList(response.items)
    }

    func fetchSuggested(page: Int, perPage: Int) async throws -> [User] {
        let response: PaginatedUsersDTO = try await networkService.requestEnvelope(
            UserProfileEndpoint.suggested(page: page, perPage: perPage)
        )
        return UserMapper.toEntityList(response.items)
    }
}
