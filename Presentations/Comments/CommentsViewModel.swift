//
 //  CommentsViewModel.swift
 //  Instagram
 //
 //  Created by Kiro on 28/7/26.
 //

import Foundation

// MARK: - CommentsViewModel

@MainActor
@Observable
final class CommentsViewModel {

    // MARK: - State

    var comments: [Comment] = []
    var isLoading = false
    var isSending = false
    var errorMessage: String?
    var replyingTo: Comment?
    var currentPage = 1
    var hasMore = false

    let contentId: String

    // MARK: - Dependencies

    private let fetchCommentsUseCase: FetchCommentsUseCaseProtocol
    private let addCommentUseCase: AddCommentUseCaseProtocol

    // MARK: - Init

    init(
        postId: String,
        fetchCommentsUseCase: FetchCommentsUseCaseProtocol,
        addCommentUseCase: AddCommentUseCaseProtocol
    ) {
        self.contentId = postId
        self.fetchCommentsUseCase = fetchCommentsUseCase
        self.addCommentUseCase = addCommentUseCase
    }

    // MARK: - Actions

    func loadComments() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Detect content type from ID prefix
            let contentType: FetchCommentsInput.ContentType = contentId.hasPrefix("reel-") ? .reel : .post
            currentPage = 1
            let input = FetchCommentsInput(contentId: contentId, contentType: contentType, page: currentPage, perPage: 20)
            let output = try await fetchCommentsUseCase.execute(input)
            comments = output.comments
            hasMore = output.hasMore
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.general.error("Failed to load comments: \(error.localizedDescription)")
        }
    }

    func loadMore() async {
        guard !isLoading, hasMore else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let contentType: FetchCommentsInput.ContentType = contentId.hasPrefix("reel-") ? .reel : .post
            currentPage += 1
            let input = FetchCommentsInput(contentId: contentId, contentType: contentType, page: currentPage, perPage: 20)
            let output = try await fetchCommentsUseCase.execute(input)
            comments.append(contentsOf: output.comments)
            hasMore = output.hasMore
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.general.error("Failed to load more comments: \(error.localizedDescription)")
        }
    }

    func addComment(text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 2200 else { return }

        isSending = true
        defer { isSending = false }

        do {
            // Detect content type from ID prefix
            let contentType: AddCommentInput.ContentType = contentId.hasPrefix("reel-") ? .reel : .post
            let input = AddCommentInput(contentId: contentId, contentType: contentType, text: trimmed)
            let newComment = try await addCommentUseCase.execute(input)
            comments.insert(newComment, at: 0)
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.general.error("Failed to add comment: \(error.localizedDescription)")
        }
    }

    func handleReply(to comment: Comment) {
        replyingTo = comment
    }

    func cancelReply() {
        replyingTo = nil
    }
}