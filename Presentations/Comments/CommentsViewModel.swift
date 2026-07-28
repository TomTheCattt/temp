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

    private(set) var comments: [Comment] = []
    private(set) var isLoading = false
    private(set) var isSending = false
    private(set) var errorMessage: String?

    private var currentPage = 1
    private var hasMorePages = true

    /// The comment being replied to (nil = top-level comment).
    var replyingTo: Comment?

    let postId: String

    // MARK: - Dependencies

    private let fetchCommentsUseCase: FetchCommentsUseCaseProtocol
    private let addCommentUseCase: AddCommentUseCaseProtocol

    // MARK: - Init

    init(
        postId: String,
        fetchCommentsUseCase: FetchCommentsUseCaseProtocol,
        addCommentUseCase: AddCommentUseCaseProtocol
    ) {
        self.postId = postId
        self.fetchCommentsUseCase = fetchCommentsUseCase
        self.addCommentUseCase = addCommentUseCase
    }

    // MARK: - Actions

    func loadComments() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        currentPage = 1

        do {
            let result = try await fetchCommentsUseCase.execute(
                FetchCommentsInput(postId: postId, page: 1)
            )
            comments = result
            hasMorePages = result.count >= 20
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadMore() async {
        guard !isLoading, hasMorePages else { return }
        isLoading = true

        let nextPage = currentPage + 1
        do {
            let result = try await fetchCommentsUseCase.execute(
                FetchCommentsInput(postId: postId, page: nextPage)
            )
            comments.append(contentsOf: result)
            currentPage = nextPage
            hasMorePages = result.count >= 20
        } catch {
            // Silent fail for pagination
        }

        isLoading = false
    }

    func addComment(text: String) async {
        guard !isSending else { return }
        isSending = true

        do {
            let comment = try await addCommentUseCase.execute(
                AddCommentInput(postId: postId, text: text, parentId: replyingTo?.id)
            )

            if replyingTo != nil {
                // Insert reply — for now append to end (proper nesting in future)
                comments.append(comment)
            } else {
                comments.insert(comment, at: 0)
            }

            replyingTo = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isSending = false
    }

    func handleReply(to comment: Comment) {
        replyingTo = comment
    }

    func cancelReply() {
        replyingTo = nil
    }
}
