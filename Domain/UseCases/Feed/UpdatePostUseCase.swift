//
//  UpdatePostUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/9/26.
//

import Foundation

// MARK: - UpdatePostInput

struct UpdatePostInput: Sendable {
    let postId: String
    let caption: String?
    let location: PostLocation?

    init(postId: String, caption: String? = nil, location: PostLocation? = nil) {
        self.postId = postId
        self.caption = caption
        self.location = location
    }
}

// MARK: - UpdatePostUseCase

/// Edits an existing post's caption/location. Media is immutable after creation,
/// matching Instagram behavior (you can only edit caption, tags, and location).
protocol UpdatePostUseCaseProtocol: Sendable {
    func execute(_ input: UpdatePostInput) async throws -> Post
}

final class UpdatePostUseCase: UpdatePostUseCaseProtocol, Sendable {

    private let postRepository: PostRepositoryProtocol

    init(postRepository: PostRepositoryProtocol) {
        self.postRepository = postRepository
    }

    func execute(_ input: UpdatePostInput) async throws -> Post {
        if let caption = input.caption, caption.count > 2200 {
            throw UpdatePostError.captionTooLong
        }

        return try await postRepository.updatePost(
            id: input.postId,
            caption: input.caption,
            location: input.location
        )
    }
}

// MARK: - UpdatePostError

private enum UpdatePostError: LocalizedError {
    case captionTooLong

    var errorDescription: String? {
        switch self {
        case .captionTooLong: return "Caption exceeds maximum length (2200 characters)."
        }
    }
}
