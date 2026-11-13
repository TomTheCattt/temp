//
//  CloseFriendsUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - CloseFriendsUseCase

protocol CloseFriendsUseCaseProtocol: Sendable {
    func fetchCandidates(currentUserId: String) async throws -> [User]
    func fetchCloseFriends() async throws -> [User]
    func setCloseFriends(userIds: [String]) async throws -> [User]
}

final class CloseFriendsUseCase: CloseFriendsUseCaseProtocol, Sendable {

    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func fetchCandidates(currentUserId: String) async throws -> [User] {
        try await userRepository.fetchFollowing(userId: currentUserId, page: 1, perPage: 100)
    }

    func fetchCloseFriends() async throws -> [User] {
        try await userRepository.fetchCloseFriends(page: 1, perPage: 100)
    }

    func setCloseFriends(userIds: [String]) async throws -> [User] {
        try await userRepository.setCloseFriends(userIds: userIds)
    }
}
