//
//  AddCommentUseCase.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - AddCommentInput

struct AddCommentInput: Sendable {
    let postId: String
    let text: String
    let parentId: String? // nil = top-level comment, non-nil = reply

    init(postId: String, text: String, parentId: String? = nil) {
        self.postId = postId
        self.text = text
        self.parentId = parentId
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

        return try await commentRepository.addComment(
            postId: input.postId,
            text: trimmed,
            parentId: input.parentId
        )
    }
}
