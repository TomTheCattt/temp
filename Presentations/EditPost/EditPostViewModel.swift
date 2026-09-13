//
//  EditPostViewModel.swift
//  Instagram
//
//  Created by Kiro on 13/9/26.
//

import SwiftUI

// MARK: - EditPostViewModel

/// Drives the "Edit info" screen for an existing post.
/// Loads the post via `FetchPostDetailUseCase`, exposes the editable caption/location,
/// and persists changes through `UpdatePostUseCase` (media is immutable, like Instagram).
@MainActor
@Observable
final class EditPostViewModel {

    // MARK: - Editable State

    /// Editable caption bound to the text editor.
    var caption: String = ""

    /// Editable location name. Cleared → sends `nil` location on save.
    var locationName: String = ""

    // MARK: - Loaded State

    /// The loaded post (nil while loading / on fetch failure).
    private(set) var post: Post?

    // MARK: - Original Values (change tracking)

    private var originalCaption: String = ""
    private var originalLocationName: String = ""

    // MARK: - Status

    private(set) var isLoading = false
    private(set) var isSaving = false
    var errorMessage: String?

    /// Set to `true` after a successful save so the view can dismiss the sheet.
    private(set) var didSave = false

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
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let post = try await fetchPostDetailUseCase.execute(FetchPostDetailInput(postId: postId))
            self.post = post

            let loadedCaption = post.caption ?? ""
            let loadedLocation = post.location?.name ?? ""

            caption = loadedCaption
            locationName = loadedLocation
            originalCaption = loadedCaption
            originalLocationName = loadedLocation
        } catch {
            errorMessage = error.userMessage
        }

        isLoading = false
    }

    // MARK: - Save

    func save() async {
        guard canSave else { return }
        isSaving = true
        errorMessage = nil
        HUDManager.shared.showLoading(L10n.HUD.saving)

        let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = locationName.trimmingCharacters(in: .whitespacesAndNewlines)

        let location: PostLocation? = trimmedLocation.isEmpty
            ? nil
            : PostLocation(
                name: trimmedLocation,
                latitude: post?.location?.latitude,
                longitude: post?.location?.longitude
            )

        do {
            _ = try await updatePostUseCase.execute(
                UpdatePostInput(
                    postId: postId,
                    caption: trimmedCaption.isEmpty ? nil : trimmedCaption,
                    location: location
                )
            )
            didSave = true
            HUDManager.shared.showSuccess(L10n.HUD.saved)
        } catch {
            HUDManager.shared.showError(error.userMessage)
            ToastManager.shared.error(error.userMessage)
        }

        isSaving = false
    }

    // MARK: - Computed

    /// The post's first media item — shown as a read-only preview.
    var previewMedia: MediaItem? {
        post?.mediaItems.first
    }

    /// Author username shown in the header (read-only).
    var authorUsername: String {
        post?.author.username ?? ""
    }

    var captionCharacterCount: Int {
        caption.count
    }

    var isCaptionValid: Bool {
        caption.count <= DS.Layout.maxCaptionLength
    }

    /// Whether the caption or location differ from the loaded values.
    var hasChanges: Bool {
        caption != originalCaption || locationName != originalLocationName
    }

    /// Done is enabled only when the post is loaded, changes exist, caption is valid,
    /// and no save is in flight.
    var canSave: Bool {
        post != nil && hasChanges && isCaptionValid && !isSaving
    }
}
