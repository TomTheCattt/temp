//
//  FetchSuggestedUsersUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - FetchSuggestedUsersUseCase

protocol FetchSuggestedUsersUseCaseProtocol: Sendable {
    func execute(page: Int, perPage: Int) async throws -> [User]
}

final class FetchSuggestedUsersUseCase: FetchSuggestedUsersUseCaseProtocol, Sendable {

    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func execute(page: Int = 1, perPage: Int = 20) async throws -> [User] {
        try await userRepository.fetchSuggested(page: page, perPage: perPage)
    }
}
