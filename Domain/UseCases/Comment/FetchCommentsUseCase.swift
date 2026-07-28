//
//  FetchCommentsUseCase.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - FetchCommentsInput

struct FetchCommentsInput: Sendable {
    let postId: String
    let page: Int
    let perPage: Int

    init(postId: String, page: Int = 1, perPage: Int = 20) {
        self.postId = postId
        self.page = page
        self.perPage = perPage
    }
}

// MARK: - FetchCommentsUseCase

protocol FetchCommentsUseCaseProtocol: Sendable {
    func execute(_ input: FetchCommentsInput) async throws -> [Comment]
}

final class FetchCommentsUseCase: FetchCommentsUseCaseProtocol, Sendable {

    private let commentRepository: CommentRepositoryProtocol

    init(commentRepository: CommentRepositoryProtocol) {
        self.commentRepository = commentRepository
    }

    func execute(_ input: FetchCommentsInput) async throws -> [Comment] {
        try await commentRepository.fetchComments(
            postId: input.postId,
            page: input.page,
            perPage: input.perPage
        )
    }
}
