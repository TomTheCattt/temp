//
//  FetchFollowersUseCase.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - FetchFollowListInput

struct FetchFollowListInput: Sendable {
    let userId: String
    let page: Int
    let perPage: Int

    init(userId: String, page: Int = 1, perPage: Int = 30) {
        self.userId = userId
        self.page = page
        self.perPage = perPage
    }
}

// MARK: - FetchFollowersUseCase

protocol FetchFollowersUseCaseProtocol: Sendable {
    func execute(_ input: FetchFollowListInput) async throws -> [User]
}

final class FetchFollowersUseCase: FetchFollowersUseCaseProtocol, Sendable {

    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func execute(_ input: FetchFollowListInput) async throws -> [User] {
        try await userRepository.fetchFollowers(userId: input.userId, page: input.page, perPage: input.perPage)
    }
}

// MARK: - FetchFollowingUseCase

protocol FetchFollowingUseCaseProtocol: Sendable {
    func execute(_ input: FetchFollowListInput) async throws -> [User]
}

final class FetchFollowingUseCase: FetchFollowingUseCaseProtocol, Sendable {

    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func execute(_ input: FetchFollowListInput) async throws -> [User] {
        try await userRepository.fetchFollowing(userId: input.userId, page: input.page, perPage: input.perPage)
    }
}
