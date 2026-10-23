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
        // TODO: Implement loadComments logic from scratch
    }

    func loadMore() async {
        // TODO: Implement loadMore comments logic from scratch
    }

    func addComment(text: String) async {
        _ = text
        // TODO: Implement addComment logic from scratch
    }

    func handleReply(to comment: Comment) {
        replyingTo = comment
    }

    func cancelReply() {
        replyingTo = nil
    }
}
