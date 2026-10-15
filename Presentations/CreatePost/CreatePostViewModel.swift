//
//  CreatePostViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import Photos
import PhotosUI

// MARK: - CreatePostStep

enum CreatePostStep: Int, CaseIterable {
    case selectMedia      // Instagram 50/50 Native Gallery Viewport
    case applyFilter      // Filter & Adjustments Edit Studio
    case captionAndShare  // Caption, Tags, Music, Location, Privacy & Share
}

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

// MARK: - PostAdjustmentType

enum PostAdjustmentType: String, CaseIterable, Identifiable {
    case brightness = "Độ sáng"
    case contrast = "Độ tương phản"
    case saturation = "Độ bão hòa"
    case warmth = "Độ ấm"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .brightness: return "sun.max"
        case .contrast:   return "circle.righthalf.filled"
        case .saturation: return "paintpalette"
        case .warmth:     return "thermometer.sun"
        }
    }
}

// MARK: - CreatePostViewModel

@MainActor
@Observable
final class CreatePostViewModel {

    // MARK: - Navigation State

    var currentStep: CreatePostStep = .selectMedia

    // MARK: - Step 1: Native Photo Library & Viewport State

    var albums: [MediaAlbumItem] = []
    var selectedAlbum: MediaAlbumItem?
    var mediaAssets: [MediaAssetItem] = []
    var selectedMediaAssets: [MediaAssetItem] = []
    var activeAsset: MediaAssetItem?
    var activePreviewImage: UIImage?
    var isMultiSelectEnabled: Bool = false
    var aspectRatio: PostAspectRatio = .square
    var isLoadingAssets: Bool = false
    var hasPhotoLibraryAccess: Bool = false

    // MARK: - Step 2: Filter & Adjustments State

    var selectedImages: [Data] = []
    var activeImageIndex: Int = 0
    var selectedFilterId: String = "original"
    var filterIntensity: Float = 1.0

    // Adjustments
    var activeAdjustment: PostAdjustmentType? = nil
    var brightness: Float = 0.0     // Range: -0.5 to 0.5 (0 = normal)
    var contrast: Float = 1.0       // Range: 0.5 to 1.5 (1.0 = normal)
    var saturation: Float = 1.0     // Range: 0.0 to 2.0 (1.0 = normal)
    var warmth: Float = 0.0         // Range: -0.5 to 0.5 (0 = normal)

    // MARK: - Step 3: Caption, Metadata & Share State

    var caption: String = ""
    var location: PostLocation?
    var selectedAudioTrack: String? = nil
    var taggedUsers: [String] = []
    var isCloseFriendsOnly: Bool = false
    var hideLikes: Bool = false
    var disableComments: Bool = false
    var shareToFacebook: Bool = false

    // Publish status
    private(set) var isPublishing = false
    private(set) var isPublished = false

    // MARK: - Dependencies

    private let createPostUseCase: CreatePostUseCaseProtocol
    private let photoLibraryService: PhotoLibraryServiceProtocol = PhotoLibraryService.shared

    // MARK: - Init

    init(createPostUseCase: CreatePostUseCaseProtocol) {
        self.createPostUseCase = createPostUseCase
    }

    // MARK: - Library Loading

    func loadInitialLibrary() async {
        isLoadingAssets = true
        let authorized = await photoLibraryService.requestAuthorization()
        self.hasPhotoLibraryAccess = authorized

        if authorized {
            let loadedAlbums = await photoLibraryService.fetchAlbums()
            self.albums = loadedAlbums
            self.selectedAlbum = loadedAlbums.first

            let assets = await photoLibraryService.fetchAssets(in: selectedAlbum, limit: 150)
            self.mediaAssets = assets

            if let first = assets.first {
                self.activeAsset = first
                self.selectedMediaAssets = [first]
                await loadPreviewImage(for: first)
            }
        }
        isLoadingAssets = false
    }

    func selectAlbum(_ album: MediaAlbumItem) async {
        selectedAlbum = album
        isLoadingAssets = true
        let assets = await photoLibraryService.fetchAssets(in: album, limit: 150)
        self.mediaAssets = assets
        if let first = assets.first, selectedMediaAssets.isEmpty {
            self.activeAsset = first
            self.selectedMediaAssets = [first]
            await loadPreviewImage(for: first)
        }
        isLoadingAssets = false
    }

    func loadPreviewImage(for asset: MediaAssetItem) async {
        if let image = await photoLibraryService.loadHighQualityImage(for: asset.phAsset) {
            self.activePreviewImage = image
        }
    }

    // MARK: - Asset Selection

    func toggleAssetSelection(_ asset: MediaAssetItem) {
        if isMultiSelectEnabled {
            if let index = selectedMediaAssets.firstIndex(of: asset) {
                // If removing the currently active asset, update active asset
                selectedMediaAssets.remove(at: index)
                if activeAsset == asset {
                    activeAsset = selectedMediaAssets.last
                    if let newActive = activeAsset {
                        Task { await loadPreviewImage(for: newActive) }
                    }
                }
            } else {
                guard selectedMediaAssets.count < 10 else {
                    HUDManager.shared.showInfo("Tối đa 10 ảnh hoặc video")
                    return
                }
                selectedMediaAssets.append(asset)
                activeAsset = asset
                Task { await loadPreviewImage(for: asset) }
            }
        } else {
            // Single selection mode
            selectedMediaAssets = [asset]
            activeAsset = asset
            Task { await loadPreviewImage(for: asset) }
        }
    }

    func toggleMultiSelect() {
        isMultiSelectEnabled.toggle()
        if !isMultiSelectEnabled && selectedMediaAssets.count > 1 {
            // Revert to only the active asset
            if let active = activeAsset {
                selectedMediaAssets = [active]
            } else if let first = selectedMediaAssets.first {
                selectedMediaAssets = [first]
                activeAsset = first
            }
        }
    }

    func toggleAspectRatio() {
        aspectRatio = (aspectRatio == .square) ? .portrait : .square
    }

    func setCapturedMedia(data: Data, isVideo: Bool = false) {
        let optimized = ImageDownsampler.shared.downsampleToData(data: data) ?? data
        selectedImages = [optimized]
        activeImageIndex = 0
        currentStep = .applyFilter
    }

    // MARK: - Navigation Transitions

    func goToNextStep() async {
        switch currentStep {
        case .selectMedia:
            // Prepare high-res images for Step 2
            HUDManager.shared.showLoading("Đang xử lý ảnh...")
            var imagesData: [Data] = []
            for item in selectedMediaAssets {
                if let data = await photoLibraryService.loadImageData(for: item.phAsset) {
                    let downsampled = ImageDownsampler.shared.downsampleToData(data: data, maxDimension: 1080) ?? data
                    imagesData.append(downsampled)
                }
            }
            HUDManager.shared.dismiss()

            if !imagesData.isEmpty {
                self.selectedImages = imagesData
                self.activeImageIndex = 0
                self.currentStep = .applyFilter
            } else if let preview = activePreviewImage, let jpeg = preview.jpegData(compressionQuality: 0.9) {
                self.selectedImages = [jpeg]
                self.activeImageIndex = 0
                self.currentStep = .applyFilter
            }

        case .applyFilter:
            // Bake filter & adjustments into selected images before moving to caption
            bakeStudioAdjustments()
            currentStep = .captionAndShare

        case .captionAndShare:
            break
        }
    }

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

    // MARK: - Filter & Adjustment Baking

    func bakeStudioAdjustments() {
        guard !selectedImages.isEmpty else { return }

        selectedImages = selectedImages.map { data in
            guard let uiImage = UIImage(data: data),
                  var ciImage = CIImage(image: uiImage) else {
                return data
            }

            // 1. Apply Selected Filter
            if selectedFilterId != "original",
               let filter = FilterRegistry.filter(byId: selectedFilterId) {
                ciImage = FilterEngine.shared.apply(filter: filter, to: ciImage, intensity: filterIntensity)
            }

            // 2. Apply Custom Adjustments (Brightness, Contrast, Saturation, Warmth)
            if brightness != 0.0 || contrast != 1.0 || saturation != 1.0 {
                let colorControls = CIFilter.colorControls()
                colorControls.inputImage = ciImage
                colorControls.brightness = brightness
                colorControls.contrast = contrast
                colorControls.saturation = saturation
                if let output = colorControls.outputImage {
                    ciImage = output
                }
            }

            if warmth != 0.0 {
                let tempFilter = CIFilter.temperatureAndTint()
                tempFilter.inputImage = ciImage
                let targetTemp = 6500.0 + Double(warmth * 2500.0)
                tempFilter.neutral = CIVector(x: CGFloat(targetTemp), y: 0)
                if let output = tempFilter.outputImage {
                    ciImage = output
                }
            }

            // Render to UIImage
            if let rendered = FilterEngine.shared.renderToUIImage(ciImage),
               let jpeg = rendered.jpegData(compressionQuality: 0.88) {
                return jpeg
            }

            return data
        }
    }

    // MARK: - Publish

    func publish() async {
        guard !isPublishing, !selectedImages.isEmpty else { return }
        isPublishing = true
        HUDManager.shared.showLoading(L10n.HUD.publishing)

        do {
            let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
            let post = try await createPostUseCase.execute(
                CreatePostInput(
                    caption: trimmedCaption.isEmpty ? nil : trimmedCaption,
                    mediaData: selectedImages,
                    location: location
                )
            )
            NotificationCenter.default.post(name: .didCreatePost, object: post)
            isPublished = true
            HUDManager.shared.showSuccess(L10n.HUD.published)
        } catch {
            HUDManager.shared.showError(error.userMessage)
        }

        isPublishing = false
    }

    func reset() {
        currentStep = .selectMedia
        selectedMediaAssets = []
        selectedImages = []
        selectedFilterId = "original"
        filterIntensity = 1.0
        brightness = 0.0
        contrast = 1.0
        saturation = 1.0
        warmth = 0.0
        caption = ""
        location = nil
        selectedAudioTrack = nil
        taggedUsers = []
        isPublished = false
    }

    // MARK: - Computed Properties

    var canProceedFromMedia: Bool {
        !selectedMediaAssets.isEmpty || !selectedImages.isEmpty
    }

    var canPublish: Bool {
        !selectedImages.isEmpty && !isPublishing
    }
}
