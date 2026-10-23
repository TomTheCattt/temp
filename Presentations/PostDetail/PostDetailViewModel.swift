//
//  PostDetailViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - PostDetailViewModel

@MainActor
@Observable
final class PostDetailViewModel {

    // MARK: - State

    var post: Post?
    var comments: [Comment] = []
    var isLoading = false
    var isLoadingComments = false
    var errorMessage: String?

    let postId: String

    // MARK: - Dependencies

    private let fetchPostDetailUseCase: FetchPostDetailUseCaseProtocol
    private let fetchCommentsUseCase: FetchCommentsUseCaseProtocol
    private let toggleLikeUseCase: ToggleLikePostUseCaseProtocol
    private let addCommentUseCase: AddCommentUseCaseProtocol

    // MARK: - Init

    init(
        postId: String,
        fetchPostDetailUseCase: FetchPostDetailUseCaseProtocol,
        fetchCommentsUseCase: FetchCommentsUseCaseProtocol,
        toggleLikeUseCase: ToggleLikePostUseCaseProtocol,
        addCommentUseCase: AddCommentUseCaseProtocol
    ) {
        self.postId = postId
        self.fetchPostDetailUseCase = fetchPostDetailUseCase
        self.fetchCommentsUseCase = fetchCommentsUseCase
        self.toggleLikeUseCase = toggleLikeUseCase
        self.addCommentUseCase = addCommentUseCase
    }

    // MARK: - Actions

    func loadPost() async {
        // TODO: Implement loadPost logic from scratch
    }

    func loadComments() async {
        // TODO: Implement loadComments logic from scratch
    }

    func toggleLike() async {
        // TODO: Implement toggleLike logic from scratch
    }

    func addComment(text: String) async {
        _ = text
        // TODO: Implement addComment logic from scratch
    }
}
