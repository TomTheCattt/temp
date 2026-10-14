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

    /// Currently selected filter id for preview and baking (defaults to "original").
    var selectedFilterId: String = "original"

    /// Filter intensity (0.0 to 1.0).
    var filterIntensity: Float = 1.0

    /// Currently active image index when multiple images are selected.
    var activeImageIndex: Int = 0

    /// Caption text.
    var caption: String = ""

    /// Location (optional).
    var location: PostLocation?

    /// Publishing state.
    private(set) var isPublishing = false
    private(set) var isLoadingMedia = false
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
        HUDManager.shared.showLoading(L10n.HUD.publishing)

        do {
            let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
            let bakedImages = bakeFilteredImages()
            let post = try await createPostUseCase.execute(
                CreatePostInput(
                    caption: trimmedCaption.isEmpty ? nil : trimmedCaption,
                    mediaData: bakedImages,
                    location: location
                )
            )
            NotificationCenter.default.post(name: .didCreatePost, object: post)
            isPublished = true
            HUDManager.shared.showSuccess(L10n.HUD.published)
        } catch {
            // Surfaced via the global HUD only — avoid a duplicate alert.
            HUDManager.shared.showError(error.userMessage)
        }

        isPublishing = false
    }

    /// Renders the chosen filter into the selected images before upload.
    private func bakeFilteredImages() -> [Data] {
        guard selectedFilterId != "original",
              let filter = FilterRegistry.filter(byId: selectedFilterId) else {
            return selectedImages
        }
        let engine = FilterEngine.shared
        return selectedImages.map { data in
            guard let uiImage = UIImage(data: data),
                  let ciImage = CIImage(image: uiImage) else {
                return data
            }
            let filtered = engine.apply(filter: filter, to: ciImage, intensity: filterIntensity)
            if let result = engine.renderToUIImage(filtered),
               let jpeg = result.jpegData(compressionQuality: 0.85) {
                return jpeg
            }
            return data
        }
    }

    /// Reset all state for a new post.
    func reset() {
        currentStep = .selectMedia
        selectedItems = []
        selectedImages = []
        selectedFilterId = "original"
        filterIntensity = 1.0
        activeImageIndex = 0
        caption = ""
        location = nil
        isPublished = false
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
