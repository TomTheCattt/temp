//
//  ToggleFollowUseCase.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - ToggleFollowInput

struct ToggleFollowInput: Sendable {
    let userId: String
    let isCurrentlyFollowing: Bool
}

// MARK: - ToggleFollowUseCase

protocol ToggleFollowUseCaseProtocol: Sendable {
    func execute(_ input: ToggleFollowInput) async throws
}

final class ToggleFollowUseCase: ToggleFollowUseCaseProtocol, Sendable {

    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func execute(_ input: ToggleFollowInput) async throws {
        if input.isCurrentlyFollowing {
            try await userRepository.unfollow(userId: input.userId)
        } else {
            try await userRepository.follow(userId: input.userId)
        }
    }
}
