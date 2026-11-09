//
//  UpdateProfileUseCase.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - UpdateProfileInput

/// Input for updating the display name (uses /v1/user/profile alias - accepts { name } only)
struct UpdateProfileNameInput: Sendable {
    let name: String

    init(name: String) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Input for updating the full profile (uses /v1/users/me canonical endpoint)
struct UpdateFullProfileInput: Sendable {
    let fullName: String?
    let bio: String?
    let website: String?
    let isPrivate: Bool?

    init(fullName: String? = nil, bio: String? = nil, website: String? = nil, isPrivate: Bool? = nil) {
        self.fullName = fullName?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.bio = bio
        self.website = website?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isPrivate = isPrivate
    }
}

// MARK: - UpdateProfileUseCase

protocol UpdateProfileUseCaseProtocol: Sendable {
    func updateName(_ input: UpdateProfileNameInput) async throws -> User
    func updateFullProfile(_ input: UpdateFullProfileInput) async throws -> User
}

final class UpdateProfileUseCase: UpdateProfileUseCaseProtocol, Sendable {

    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func updateName(_ input: UpdateProfileNameInput) async throws -> User {
        guard !input.name.isEmpty else {
            throw UpdateProfileError.emptyName
        }
        return try await userRepository.updateProfileName(input.name)
    }

    func updateFullProfile(_ input: UpdateFullProfileInput) async throws -> User {
        // Validate bio length
        if let bio = input.bio, bio.count > 150 {
            throw UpdateProfileError.bioTooLong
        }

        // Validate and normalize website URL if provided
        let cleanedWebsite: String?
        if let website = input.website, !website.isEmpty {
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

        return try await userRepository.updateFullProfile(
            fullName: input.fullName,
            bio: input.bio,
            website: cleanedWebsite,
            isPrivate: input.isPrivate
        )
    }
}

// MARK: - UpdateProfileError

private enum UpdateProfileError: LocalizedError {
    case bioTooLong
    case invalidWebsite
    case emptyName

    var errorDescription: String? {
        switch self {
        case .bioTooLong:      return "Bio must be 150 characters or less."
        case .invalidWebsite:  return "Invalid website URL."
        case .emptyName:       return "Name cannot be empty."
        }
    }
}
