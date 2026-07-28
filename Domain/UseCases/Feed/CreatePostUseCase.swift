//
//  CreatePostUseCase.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - CreatePostInput

struct CreatePostInput: Sendable {
    let caption: String?
    let mediaData: [Data]
    let location: PostLocation?

    init(caption: String? = nil, mediaData: [Data], location: PostLocation? = nil) {
        self.caption = caption
        self.mediaData = mediaData
        self.location = location
    }
}

// MARK: - CreatePostUseCase

protocol CreatePostUseCaseProtocol: Sendable {
    func execute(_ input: CreatePostInput) async throws -> Post
}

final class CreatePostUseCase: CreatePostUseCaseProtocol, Sendable {

    private let postRepository: PostRepositoryProtocol

    init(postRepository: PostRepositoryProtocol) {
        self.postRepository = postRepository
    }

    func execute(_ input: CreatePostInput) async throws -> Post {
        // Validate
        guard !input.mediaData.isEmpty else {
            throw CreatePostError.noMedia
        }
        guard input.mediaData.count <= 10 else {
            throw CreatePostError.tooManyMedia
        }
        if let caption = input.caption, caption.count > 2200 {
            throw CreatePostError.captionTooLong
        }

        return try await postRepository.createPost(
            caption: input.caption,
            mediaData: input.mediaData,
            location: input.location
        )
    }
}

// MARK: - CreatePostError

private enum CreatePostError: LocalizedError {
    case noMedia
    case tooManyMedia
    case captionTooLong

    var errorDescription: String? {
        switch self {
        case .noMedia:        return "At least one photo or video is required."
        case .tooManyMedia:   return "Maximum 10 items per post."
        case .captionTooLong: return "Caption exceeds maximum length (2200 characters)."
        }
    }
}
