//
//  UserRepository.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - UserRepository

final class UserRepository: UserRepositoryProtocol, @unchecked Sendable {

    private let remoteDataSource: RemoteUserDataSource

    init(remoteDataSource: RemoteUserDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchCurrentUser() async throws -> User {
        try await remoteDataSource.fetchCurrentUser()
    }

    func fetchUser(id: String) async throws -> User {
        try await remoteDataSource.fetchUser(id: id)
    }

    func searchUsers(query: String, page: Int, perPage: Int) async throws -> [User] {
        try await remoteDataSource.searchUsers(query: query, page: page, perPage: perPage)
    }

    func updateProfile(name: String?, bio: String?, website: String?) async throws -> User {
        try await remoteDataSource.updateProfile(name: name, bio: bio, website: website)
    }

    func updateAvatar(imageData: Data) async throws -> User {
        try await remoteDataSource.updateAvatar(imageData: imageData)
    }

    func follow(userId: String) async throws {
        try await remoteDataSource.follow(userId: userId)
    }

    func unfollow(userId: String) async throws {
        try await remoteDataSource.unfollow(userId: userId)
    }

    func block(userId: String) async throws {
        try await remoteDataSource.block(userId: userId)
    }

    func unblock(userId: String) async throws {
        try await remoteDataSource.unblock(userId: userId)
    }

    func fetchFollowers(userId: String, page: Int, perPage: Int) async throws -> [User] {
        try await remoteDataSource.fetchFollowers(userId: userId, page: page, perPage: perPage)
    }

    func fetchFollowing(userId: String, page: Int, perPage: Int) async throws -> [User] {
        try await remoteDataSource.fetchFollowing(userId: userId, page: page, perPage: perPage)
    }

    func fetchSuggested(page: Int, perPage: Int) async throws -> [User] {
        try await remoteDataSource.fetchSuggested(page: page, perPage: perPage)
    }
}
