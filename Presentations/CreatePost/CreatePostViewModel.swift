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

// MARK: - PostAspectRatio

enum PostAspectRatio: String, CaseIterable, Identifiable {
    case square = "1:1"
    case portrait = "4:5"

    var id: String { rawValue }

    var ratioValue: CGFloat {
        switch self {
        case .square: return 1.0
        case .portrait: return 4.0 / 5.0
        }
    }
}

// MARK: - CreatePostViewModel

@MainActor
@Observable
final class CreatePostViewModel {

    // MARK: - State

    var currentStep: CreatePostStep = .selectMedia

    /// Selected photo items from PhotosPicker.
    var selectedItems: [PhotosPickerItem] = []

    /// Loaded images (UIImage data) from selection or camera/canvas.
    private(set) var selectedImages: [Data] = []

    /// Aspect ratio for the post preview.
    var aspectRatio: PostAspectRatio = .square

    /// Currently selected filter id for preview and baking (defaults to "original").
    var selectedFilterId: String = "original"

    /// Filter intensity (0.0 to 1.0).
    var filterIntensity: Float = 1.0

    /// Currently active image index when multiple images are selected.
    var activeImageIndex: Int = 0

    /// Multi-layer PIP stickers on the active image.
    var stickers: [PIPStickerItem] = []

    /// Multi-layer Typography items on the active image.
    var texts: [TextOverlayItem] = []

    /// Caption text.
    var caption: String = ""

    /// Location (optional).
    var location: PostLocation?

    /// Audience and Privacy settings.
    var isCloseFriendsOnly: Bool = false
    var hideLikes: Bool = false
    var disableComments: Bool = false

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

    /// Set media captured from Camera, Canvas, or Layout.
    func setCapturedMedia(data: Data, isVideo: Bool = false) {
        let optimized = ImageDownsampler.shared.downsampleToData(data: data) ?? data
        selectedImages = [optimized]
        activeImageIndex = 0
    }

    /// Append additional image data.
    func appendMedia(data: Data) {
        guard selectedImages.count < DS.Layout.maxPostMedia else { return }
        let optimized = ImageDownsampler.shared.downsampleToData(data: data) ?? data
        selectedImages.append(optimized)
    }

    /// Update image data at a specific index.
    func updateImage(at index: Int, data: Data) {
        guard index >= 0 && index < selectedImages.count else { return }
        selectedImages[index] = data
    }

    /// Remove an image from the carousel.
    func removeImage(at index: Int) {
        guard index >= 0 && index < selectedImages.count else { return }
        selectedImages.remove(at: index)
        if activeImageIndex >= selectedImages.count {
            activeImageIndex = max(0, selectedImages.count - 1)
        }
    }

    /// Toggle aspect ratio between 1:1 and 4:5.
    func toggleAspectRatio() {
        aspectRatio = (aspectRatio == .square) ? .portrait : .square
    }

    /// Load image data from PhotosPickerItems with memory-efficient downsampling.
    func loadSelectedMedia() async {
        guard !selectedItems.isEmpty else { return }
        isLoadingMedia = true
        var images: [Data] = []

        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let downsampled = ImageDownsampler.shared.downsampleToData(data: data, maxDimension: 1080) ?? data
                images.append(downsampled)
            }
        }

        selectedImages = images
        activeImageIndex = 0
        isLoadingMedia = false
    }

    /// Bakes the current filter, PIP stickers, and typography overlays into the active image.
    func bakeStudioLayers() {
        guard !selectedImages.isEmpty else { return }
        let safeIndex = min(activeImageIndex, selectedImages.count - 1)
        guard let base = UIImage(data: selectedImages[safeIndex]) else { return }

        // 1. Filter base image if needed
        var filteredBase = base
        if selectedFilterId != "original",
           let filter = FilterRegistry.filter(byId: selectedFilterId),
           let ciImage = CIImage(image: base) {
            let engine = FilterEngine.shared
            let outputCI = engine.apply(filter: filter, to: ciImage, intensity: filterIntensity)
            if let rendered = engine.renderToUIImage(outputCI) {
                filteredBase = rendered
            }
        }

        // 2. Bake stickers and typography overlays
        let composite = CompositeImageRenderer.shared.render(
            baseImage: filteredBase,
            stickers: stickers,
            texts: texts,
            renderSize: CGSize(width: 1080, height: 1080)
        )

        if let jpeg = composite.jpegData(compressionQuality: 0.85) {
            selectedImages[safeIndex] = jpeg
        }

        // 3. Reset overlays and filter for this baked image
        stickers = []
        texts = []
        selectedFilterId = "original"
        filterIntensity = 1.0
    }

    /// Switch active image in step 2 with auto-baking the previous image's layers.
    func setActiveImage(to index: Int) {
        guard index >= 0 && index < selectedImages.count, index != activeImageIndex else { return }
        if !stickers.isEmpty || !texts.isEmpty || selectedFilterId != "original" {
            bakeStudioLayers()
        }
        activeImageIndex = index
    }

    /// Move to next step.
    func goToNextStep() {
        switch currentStep {
        case .selectMedia:
            if !selectedImages.isEmpty {
                currentStep = .applyFilter
            }
        case .applyFilter:
            bakeStudioLayers()
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
        stickers = []
        texts = []
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
