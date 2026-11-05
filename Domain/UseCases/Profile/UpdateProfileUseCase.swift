//
//  UpdateProfileUseCase.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - UpdateProfileInput

struct UpdateProfileInput: Sendable {
    let fullName: String?
    let username: String?
    let bio: String?
    let website: String?
    let phone: String?
    let avatarUrl: String?

    init(fullName: String? = nil, username: String? = nil, bio: String? = nil, website: String? = nil, phone: String? = nil, avatarUrl: String? = nil) {
        self.fullName = fullName
        self.username = username
        self.bio = bio
        self.website = website
        self.phone = phone
        self.avatarUrl = avatarUrl
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

        // Validate username if provided (alphanumeric + underscore, 3-30 chars)
        if let username = input.username?.trimmingCharacters(in: .whitespacesAndNewlines), !username.isEmpty {
            let usernameRegex = "^[a-zA-Z0-9_]{3,30}$"
            let predicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
            if !predicate.evaluate(with: username) {
                throw UpdateProfileError.invalidUsername
            }
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

        // Validate phone if provided (basic format)
        let cleanedPhone: String?
        if let phone = input.phone?.trimmingCharacters(in: .whitespacesAndNewlines), !phone.isEmpty {
            cleanedPhone = phone
        } else {
            cleanedPhone = nil
        }

        return try await userRepository.updateProfile(
            fullName: input.fullName?.trimmingCharacters(in: .whitespacesAndNewlines),
            username: input.username?.trimmingCharacters(in: .whitespacesAndNewlines),
            bio: input.bio,
            website: cleanedWebsite,
            phone: cleanedPhone,
            avatarUrl: input.avatarUrl
        )
    }
}

// MARK: - UpdateProfileError

private enum UpdateProfileError: LocalizedError {
    case bioTooLong
    case invalidWebsite
    case invalidUsername

    var errorDescription: String? {
        switch self {
        case .bioTooLong:      return "Bio must be 150 characters or less."
        case .invalidWebsite:  return "Invalid website URL."
        case .invalidUsername: return "Username must be 3-30 characters and can only contain letters, numbers, and underscores."
        }
    }
}
