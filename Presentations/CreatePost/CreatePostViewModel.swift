//
//  CreatePostViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import PhotosUI

// MARK: - CreatePostStep

enum CreatePostStep: Int, CaseIterable {
    case selectMedia
    case applyFilter
    case captionAndShare
}

// MARK: - CreatePostViewModel

@MainActor
@Observable
final class CreatePostViewModel {

    // MARK: - State

    var currentStep: CreatePostStep = .selectMedia

    /// Selected photo items from PhotosPicker.
    var selectedItems: [PhotosPickerItem] = []

    /// Loaded images (UIImage data) from selection.
    private(set) var selectedImages: [Data] = []

    /// Currently selected filter for preview.
    var selectedFilterId: String?

    /// Caption text.
    var caption: String = ""

    /// Location (optional).
    var location: PostLocation?

    /// Publishing state.
    private(set) var isPublishing = false
    private(set) var isLoadingMedia = false
    var publishError: String?
    private(set) var isPublished = false

    // MARK: - Dependencies

    private let createPostUseCase: CreatePostUseCaseProtocol

    // MARK: - Init

    init(createPostUseCase: CreatePostUseCaseProtocol) {
        self.createPostUseCase = createPostUseCase
    }

    // MARK: - Actions

    /// Load image data from PhotosPickerItems.
    func loadSelectedMedia() async {
        isLoadingMedia = true
        var images: [Data] = []

        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self) {
                images.append(data)
            }
        }

        selectedImages = images
        isLoadingMedia = false

        // Auto-advance to filter step if we have images
        if !images.isEmpty {
            currentStep = .applyFilter
        }
    }

    /// Move to next step.
    func goToNextStep() {
        switch currentStep {
        case .selectMedia:
            if !selectedImages.isEmpty {
                currentStep = .applyFilter
            }
        case .applyFilter:
            currentStep = .captionAndShare
        case .captionAndShare:
            break // Final step — publish instead
        }
    }

    /// Move to previous step.
    func goToPreviousStep() {
        switch currentStep {
        case .selectMedia:
            break
        case .applyFilter:
            currentStep = .selectMedia
        case .captionAndShare:
            currentStep = .applyFilter
        }
    }

    /// Publish the post.
    func publish() async {
        guard !isPublishing, !selectedImages.isEmpty else { return }
        isPublishing = true
        publishError = nil

        do {
            let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = try await createPostUseCase.execute(
                CreatePostInput(
                    caption: trimmedCaption.isEmpty ? nil : trimmedCaption,
                    mediaData: selectedImages,
                    location: location
                )
            )
            isPublished = true
        } catch {
            publishError = error.localizedDescription
        }

        isPublishing = false
    }

    /// Reset all state for a new post.
    func reset() {
        currentStep = .selectMedia
        selectedItems = []
        selectedImages = []
        selectedFilterId = nil
        caption = ""
        location = nil
        isPublished = false
        publishError = nil
    }

    // MARK: - Computed

    var canProceedFromMedia: Bool {
        !selectedImages.isEmpty
    }

    var canPublish: Bool {
        !selectedImages.isEmpty && !isPublishing
    }

    var mediaCount: Int {
        selectedImages.count
    }
}
