//
//  UpdateProfileUseCase.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - UpdateProfileInput

struct UpdateProfileInput: Sendable {
    let name: String?
    let bio: String?
    let website: String?

    init(name: String? = nil, bio: String? = nil, website: String? = nil) {
        self.name = name
        self.bio = bio
        self.website = website
    }
}

// MARK: - UpdateProfileUseCase

protocol UpdateProfileUseCaseProtocol: Sendable {
    func execute(_ input: UpdateProfileInput) async throws -> User
}

final class UpdateProfileUseCase: UpdateProfileUseCaseProtocol, Sendable {

    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func execute(_ input: UpdateProfileInput) async throws -> User {
        // Validate bio length
        if let bio = input.bio, bio.count > 150 {
            throw UpdateProfileError.bioTooLong
        }

        // Validate website URL if provided
        if let website = input.website, !website.isEmpty {
            guard URL(string: website) != nil else {
                throw UpdateProfileError.invalidWebsite
            }
        }

        return try await userRepository.updateProfile(
            name: input.name,
            bio: input.bio,
            website: input.website
        )
    }
}

// MARK: - UpdateProfileError

private enum UpdateProfileError: LocalizedError {
    case bioTooLong
    case invalidWebsite

    var errorDescription: String? {
        switch self {
        case .bioTooLong:      return "Bio must be 150 characters or less."
        case .invalidWebsite:  return "Invalid website URL."
        }
    }
}
