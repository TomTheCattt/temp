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

    private(set) var post: Post?
    private(set) var comments: [Comment] = []
    private(set) var isLoading = false
    private(set) var isLoadingComments = false
    private(set) var errorMessage: String?

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
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            post = try await fetchPostDetailUseCase.execute(FetchPostDetailInput(postId: postId))
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadComments() async {
        guard !isLoadingComments else { return }
        isLoadingComments = true

        do {
            comments = try await fetchCommentsUseCase.execute(
                FetchCommentsInput(postId: postId)
            )
        } catch {
            // Silent fail for comments
        }

        isLoadingComments = false
    }

    func toggleLike() async {
        guard let currentPost = post else { return }

        // Optimistic update
        let newLiked = !currentPost.isLiked
        let newCount = currentPost.likesCount + (newLiked ? 1 : -1)
        post = Post(
            id: currentPost.id,
            author: currentPost.author,
            caption: currentPost.caption,
            mediaItems: currentPost.mediaItems,
            location: currentPost.location,
            likesCount: newCount,
            commentsCount: currentPost.commentsCount,
            createdAt: currentPost.createdAt,
            isLiked: newLiked,
            isSaved: currentPost.isSaved,
            isSponsored: currentPost.isSponsored
        )

        do {
            try await toggleLikeUseCase.execute(
                ToggleLikeInput(postId: currentPost.id, isCurrentlyLiked: currentPost.isLiked)
            )
        } catch {
            // Revert on failure
            post = currentPost
        }
    }

    func addComment(text: String) async {
        do {
            let comment = try await addCommentUseCase.execute(
                AddCommentInput(postId: postId, text: text)
            )
            comments.insert(comment, at: 0)

            // Update comment count
            if let currentPost = post {
                post = Post(
                    id: currentPost.id,
                    author: currentPost.author,
                    caption: currentPost.caption,
                    mediaItems: currentPost.mediaItems,
                    location: currentPost.location,
                    likesCount: currentPost.likesCount,
                    commentsCount: currentPost.commentsCount + 1,
                    createdAt: currentPost.createdAt,
                    isLiked: currentPost.isLiked,
                    isSaved: currentPost.isSaved,
                    isSponsored: currentPost.isSponsored
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
