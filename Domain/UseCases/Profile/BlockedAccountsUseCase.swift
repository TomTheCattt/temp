//
//  BlockedAccountsUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - BlockedAccountsUseCase

protocol BlockedAccountsUseCaseProtocol: Sendable {
    func fetchBlockedUsers(page: Int, perPage: Int) async throws -> [User]
    func unblock(userId: String) async throws
}

final class BlockedAccountsUseCase: BlockedAccountsUseCaseProtocol, Sendable {

    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func fetchBlockedUsers(page: Int = 1, perPage: Int = 50) async throws -> [User] {
        try await userRepository.fetchBlockedUsers(page: page, perPage: perPage)
    }

    func unblock(userId: String) async throws {
        try await userRepository.unblock(userId: userId)
    }
}
