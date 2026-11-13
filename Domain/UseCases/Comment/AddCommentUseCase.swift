//
//  AddCommentUseCase.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - AddCommentInput

struct AddCommentInput: Sendable {
    let contentId: String
    let contentType: ContentType
    let text: String
    let parentId: String? // nil = top-level comment, non-nil = reply

    init(contentId: String, contentType: ContentType, text: String, parentId: String? = nil) {
        self.contentId = contentId
        self.contentType = contentType
        self.text = text
        self.parentId = parentId
    }

    enum ContentType: Sendable {
        case post
        case reel
    }
}

// Convenience initializers for backward compatibility
extension AddCommentInput {
    init(postId: String, text: String, parentId: String? = nil) {
        self.init(contentId: postId, contentType: .post, text: text, parentId: parentId)
    }
}

// MARK: - AddCommentUseCase

protocol AddCommentUseCaseProtocol: Sendable {
    func execute(_ input: AddCommentInput) async throws -> Comment
}

final class AddCommentUseCase: AddCommentUseCaseProtocol, Sendable {

    private let commentRepository: CommentRepositoryProtocol

    init(commentRepository: CommentRepositoryProtocol) {
        self.commentRepository = commentRepository
    }

    func execute(_ input: AddCommentInput) async throws -> Comment {
        // Validate
        let trimmed = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyComment
        }
        guard trimmed.count <= 2200 else {
            throw ValidationError.commentTooLong
        }

        switch input.contentType {
        case .post:
            return try await commentRepository.addComment(
                postId: input.contentId,
                text: trimmed,
                parentId: input.parentId
            )
        case .reel:
            return try await commentRepository.addReelComment(
                reelId: input.contentId,
                text: trimmed,
                parentId: input.parentId
            )
        }
    }
}
