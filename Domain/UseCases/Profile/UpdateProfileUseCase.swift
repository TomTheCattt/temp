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

        // Validate and normalize website URL if provided
        let cleanedWebsite: String?
        if let website = input.website?.trimmingCharacters(in: .whitespacesAndNewlines), !website.isEmpty {
            let formatted = (website.lowercased().hasPrefix("http://") || website.lowercased().hasPrefix("https://"))
                ? website
                : "https://" + website

            guard let url = URL(string: formatted), url.host != nil else {
                throw UpdateProfileError.invalidWebsite
            }
            cleanedWebsite = formatted
        } else {
            cleanedWebsite = nil
        }

        return try await userRepository.updateProfile(
            name: input.name?.trimmingCharacters(in: .whitespacesAndNewlines),
            bio: input.bio,
            website: cleanedWebsite
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
