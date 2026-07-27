//
//  SearchUsersUseCase.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - SearchInput

struct SearchInput: Sendable {
    let query: String
    let page: Int
    let perPage: Int

    init(query: String, page: Int = 1, perPage: Int = 20) {
        self.query = query
        self.page = page
        self.perPage = perPage
    }
}

// MARK: - SearchUsersUseCase

protocol SearchUsersUseCaseProtocol: Sendable {
    func execute(_ input: SearchInput) async throws -> [User]
}

final class SearchUsersUseCase: SearchUsersUseCaseProtocol, Sendable {

    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func execute(_ input: SearchInput) async throws -> [User] {
        let trimmed = input.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        return try await userRepository.searchUsers(
            query: trimmed,
            page: input.page,
            perPage: input.perPage
        )
    }
}
