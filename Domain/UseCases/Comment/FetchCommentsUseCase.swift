//
 //  FetchCommentsUseCase.swift
 //  Instagram
 //
 //  Created by Kiro on 28/7/26.
 //

import Foundation

// MARK: - FetchCommentsInput

struct FetchCommentsInput: Sendable {
    let contentId: String
    let contentType: ContentType
    let page: Int
    let perPage: Int

    init(contentId: String, contentType: ContentType, page: Int = 1, perPage: Int = 20) {
        self.contentId = contentId
        self.contentType = contentType
        self.page = page
        self.perPage = perPage
    }

    enum ContentType: Sendable {
        case post
        case reel
    }
}

// Convenience initializers for backward compatibility
extension FetchCommentsInput {
    init(postId: String, page: Int = 1, perPage: Int = 20) {
        self.init(contentId: postId, contentType: .post, page: page, perPage: perPage)
    }
}

// MARK: - FetchCommentsOutput

struct FetchCommentsOutput: Sendable {
    let comments: [Comment]
    let page: Int
    let perPage: Int
    let total: Int
    let hasMore: Bool
}

// MARK: - FetchCommentsUseCase

protocol FetchCommentsUseCaseProtocol: Sendable {
    func execute(_ input: FetchCommentsInput) async throws -> FetchCommentsOutput
}

final class FetchCommentsUseCase: FetchCommentsUseCaseProtocol, Sendable {

    private let commentRepository: CommentRepositoryProtocol

    init(commentRepository: CommentRepositoryProtocol) {
        self.commentRepository = commentRepository
    }

    func execute(_ input: FetchCommentsInput) async throws -> FetchCommentsOutput {
        switch input.contentType {
        case .post:
            let result = try await commentRepository.fetchComments(
                postId: input.contentId,
                page: input.page,
                perPage: input.perPage
            )
            return FetchCommentsOutput(
                comments: result.comments,
                page: result.page,
                perPage: result.perPage,
                total: result.total,
                hasMore: result.hasMore
            )
        case .reel:
            let result = try await commentRepository.fetchReelComments(
                reelId: input.contentId,
                page: input.page,
                perPage: input.perPage
            )
            return FetchCommentsOutput(
                comments: result.comments,
                page: result.page,
                perPage: result.perPage,
                total: result.total,
                hasMore: result.hasMore
            )
        }
    }
}