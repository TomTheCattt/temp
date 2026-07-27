//
//  FetchProfileUseCase.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - FetchProfileInput

struct FetchProfileInput: Sendable {
    let userId: String?  // nil = fetch current user

    static let currentUser = FetchProfileInput(userId: nil)
}

// MARK: - FetchProfileUseCase

protocol FetchProfileUseCaseProtocol: Sendable {
    func execute(_ input: FetchProfileInput) async throws -> User
}

final class FetchProfileUseCase: FetchProfileUseCaseProtocol, Sendable {

    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func execute(_ input: FetchProfileInput) async throws -> User {
        if let userId = input.userId {
            return try await userRepository.fetchUser(id: userId)
        } else {
            return try await userRepository.fetchCurrentUser()
        }
    }
}
