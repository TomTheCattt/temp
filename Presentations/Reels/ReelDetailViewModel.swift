//
//  ReelDetailViewModel.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation
import Observation

// MARK: - Share Item

struct ShareItem: Identifiable, Sendable {
    let id = UUID()
    let url: URL
}

// MARK: - ReelDetailViewModel

@MainActor
@Observable
final class ReelDetailViewModel {

    // MARK: - State
    var reel: Reel?
    var isLoading = false
    var errorMessage: String?
    var isLiked = false
    var likeCount = 0
    var commentCount = 0
    var shareCount = 0
    var isSaved = false
    var isMuted = false
    var isCurrentUserReel = false
    var showComments = false
    var shareSheetItem: ShareItem?
    var onDelete: (() -> Void)?

    // MARK: - Dependencies
    private let reelId: String
    private let fetchReelDetailUseCase: FetchReelDetailUseCaseProtocol
    private let toggleSaveReelUseCase: ToggleSaveReelUseCaseProtocol
    private let deleteReelUseCase: DeleteReelUseCaseProtocol
    private let toggleLikeUseCase: ToggleLikePostUseCaseProtocol
    private let addCommentUseCase: AddCommentUseCaseProtocol

    // MARK: - Init
    init(
        reelId: String,
        fetchReelDetailUseCase: FetchReelDetailUseCaseProtocol,
        toggleSaveReelUseCase: ToggleSaveReelUseCaseProtocol,
        deleteReelUseCase: DeleteReelUseCaseProtocol,
        toggleLikeUseCase: ToggleLikePostUseCaseProtocol,
        addCommentUseCase: AddCommentUseCaseProtocol
    ) {
        self.reelId = reelId
        self.fetchReelDetailUseCase = fetchReelDetailUseCase
        self.toggleSaveReelUseCase = toggleSaveReelUseCase
        self.deleteReelUseCase = deleteReelUseCase
        self.toggleLikeUseCase = toggleLikeUseCase
        self.addCommentUseCase = addCommentUseCase
    }

    // MARK: - Actions
    func loadReel() async {
        isLoading = true
        errorMessage = nil

        do {
            reel = try await fetchReelDetailUseCase.execute(id: reelId)
            if let reel {
                isLiked = reel.isLiked
                likeCount = reel.likesCount
                commentCount = reel.commentsCount
                shareCount = reel.sharesCount
                isSaved = reel.isSaved
                // isCurrentUserReel: User model doesn't have isCurrentUser property yet
                // isCurrentUserReel = reel.author.isCurrentUser
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleLike() async {
        guard reel != nil else { return }
        isLiked.toggle()
        likeCount += isLiked ? 1 : -1

        do {
            try await toggleLikeUseCase.execute(ToggleLikeInput(postId: reelId, isCurrentlyLiked: !isLiked))
        } catch {
            isLiked.toggle()
            likeCount += isLiked ? 1 : -1
            errorMessage = error.localizedDescription
        }
    }

    func toggleSave() async {
        guard reel != nil else { return }
        isSaved.toggle()

        do {
            try await toggleSaveReelUseCase.execute(reelId: reelId, shouldSave: isSaved)
        } catch {
            isSaved.toggle()
            errorMessage = error.localizedDescription
        }
    }

    func toggleFollow() async {
        // Would call follow use case
    }

    func deleteReel() async {
        do {
            try await deleteReelUseCase.execute(id: reelId)
            onDelete?()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func shareReel() {
        // No need to check reel since we use reelId
        let shareURL = URL(string: "https://instagram.com/reel/\(reelId)")!
        shareSheetItem = ShareItem(url: shareURL)
    }

    func showAudioDetail() {
        // Navigate to audio detail page
    }

    func handleVideoEnded() {
        // Loop video or load next
    }
}
