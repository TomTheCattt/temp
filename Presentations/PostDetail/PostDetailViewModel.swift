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
    var currentCommentPage = 1
    var hasMoreComments = false

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
        defer { isLoading = false }

        do {
            let input = FetchPostDetailInput(postId: postId)
            post = try await fetchPostDetailUseCase.execute(input)
            // Load initial comments
            await loadComments()
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.general.error("Failed to load post: \(error.localizedDescription)")
        }
    }

    func loadComments() async {
        guard !isLoadingComments else { return }
        isLoadingComments = true
        defer { isLoadingComments = false }

        do {
            // Detect content type from ID prefix
            let contentType: FetchCommentsInput.ContentType = postId.hasPrefix("reel-") ? .reel : .post
            currentCommentPage = 1
            let input = FetchCommentsInput(contentId: postId, contentType: contentType, page: currentCommentPage, perPage: 20)
            let output = try await fetchCommentsUseCase.execute(input)
            comments = output.comments
            hasMoreComments = output.hasMore
        } catch {
            AppLogger.general.error("Failed to load comments: \(error.localizedDescription)")
        }
    }

    func loadMoreComments() async {
        guard !isLoadingComments, hasMoreComments else { return }
        isLoadingComments = true
        defer { isLoadingComments = false }

        do {
            let contentType: FetchCommentsInput.ContentType = postId.hasPrefix("reel-") ? .reel : .post
            currentCommentPage += 1
            let input = FetchCommentsInput(contentId: postId, contentType: contentType, page: currentCommentPage, perPage: 20)
            let output = try await fetchCommentsUseCase.execute(input)
            comments.append(contentsOf: output.comments)
            hasMoreComments = output.hasMore
        } catch {
            AppLogger.general.error("Failed to load more comments: \(error.localizedDescription)")
        }
    }

    func toggleLike() async {
        guard let post = post else { return }
        do {
            let newLikeState = !post.isLiked
            try await toggleLikeUseCase.execute(ToggleLikeInput(postId: post.id, isCurrentlyLiked: post.isLiked))
            // Update local state optimistically using helper method
            self.post = self.post?.withLike(newLikeState)
        } catch {
            AppLogger.general.error("Failed to toggle like: \(error.localizedDescription)")
        }
    }

    func addComment(text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 2200 else { return }

        do {
            // Detect content type from ID prefix
            let contentType: AddCommentInput.ContentType = postId.hasPrefix("reel-") ? .reel : .post
            let input = AddCommentInput(contentId: postId, contentType: contentType, text: trimmed)
            let newComment = try await addCommentUseCase.execute(input)
            // Update local state optimistically
            comments.insert(newComment, at: 0)
            // Note: Post commentsCount is immutable, so it won't be updated optimistically
            // The count will be correct after the next refresh
        } catch {
            AppLogger.general.error("Failed to add comment: \(error.localizedDescription)")
        }
    }
}