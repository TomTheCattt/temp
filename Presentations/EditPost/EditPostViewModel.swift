//
//  EditPostViewModel.swift
//  Instagram
//
//  Created by Kiro on 13/9/26.
//

import SwiftUI

// MARK: - EditPostViewModel

@MainActor
@Observable
final class EditPostViewModel {

    // MARK: - Editable State

    var caption: String = ""
    var locationName: String = ""

    // MARK: - Loaded State

    var post: Post?

    // MARK: - Status

    var isLoading = false
    var isSaving = false
    var errorMessage: String?
    var didSave = false

    // MARK: - Dependencies

    private let postId: String
    private let fetchPostDetailUseCase: FetchPostDetailUseCaseProtocol
    private let updatePostUseCase: UpdatePostUseCaseProtocol

    // MARK: - Init

    init(
        postId: String,
        fetchPostDetailUseCase: FetchPostDetailUseCaseProtocol,
        updatePostUseCase: UpdatePostUseCaseProtocol
    ) {
        self.postId = postId
        self.fetchPostDetailUseCase = fetchPostDetailUseCase
        self.updatePostUseCase = updatePostUseCase
    }

    // MARK: - Load

    func loadPost() async {
        // TODO: Implement loadPost logic from scratch
    }

    // MARK: - Save

    func save() async {
        // TODO: Implement updatePost save logic from scratch
    }

    // MARK: - Computed

    var previewMedia: MediaItem? {
        post?.mediaItems.first
    }

    var authorUsername: String {
        post?.author.username ?? ""
    }

    var captionCharacterCount: Int {
        caption.count
    }

    var isCaptionValid: Bool {
        caption.count <= DS.Layout.maxCaptionLength
    }

    var hasChanges: Bool {
        true
    }

    var canSave: Bool {
        post != nil && isCaptionValid && !isSaving
    }
}
