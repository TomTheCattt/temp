//
//  StoryCameraViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import AVFoundation
import Photos

// MARK: - StoryCameraMode

public enum StoryCameraMode: String, CaseIterable, Identifiable {
    case normal = "Normal"
    case create = "Create"
    case layout = "Layout"
    case boomerang = "Boomerang"
    case hands_free = "Hands-Free"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .normal:     return "camera"
        case .create:     return "textformat"
        case .layout:     return "square.grid.2x2"
        case .boomerang:  return "infinity"
        case .hands_free: return "hand.raised.fill"
        }
    }
}

// MARK: - StoryFilter

public struct StoryFilter: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let filterId: String

    public static let allFilters: [StoryFilter] = [
        StoryFilter(id: "normal", name: "Normal", filterId: "original"),
        StoryFilter(id: "paris", name: "Paris", filterId: "clarendon"),
        StoryFilter(id: "oslo", name: "Oslo", filterId: "gingham"),
        StoryFilter(id: "tokyo", name: "Tokyo", filterId: "juno"),
        StoryFilter(id: "melbourne", name: "Melbourne", filterId: "lark"),
        StoryFilter(id: "cairo", name: "Cairo", filterId: "slumber")
    ]
}

// MARK: - StoryCameraViewModel

@MainActor
@Observable
final class StoryCameraViewModel {

    // MARK: - State

    var mode: StoryCameraMode = .normal
    var isRecording = false
    var isFrontCamera = true
    var isFlashOn = false

    // Multi-layer Story Overlays
    var stickers: [PIPStickerItem] = []
    var texts: [TextOverlayItem] = []
    var currentFilterIndex: Int = 0

    var currentFilter: StoryFilter {
        StoryFilter.allFilters[currentFilterIndex % StoryFilter.allFilters.count]
    }

    /// Latest gallery thumbnail for the bottom-left camera roll shortcut.
    var latestGalleryThumbnail: UIImage?

    /// Captured media data (photo or video).
    private(set) var capturedImageData: Data?
    private(set) var capturedVideoURL: URL?

    /// Whether we have media ready for editing.
    var hasCapturedMedia: Bool {
        capturedImageData != nil || capturedVideoURL != nil
    }

    /// Show the edit/preview screen after capture.
    var isShowingPreview = false

    /// Publishing state.
    private(set) var isPublishing = false
    private(set) var isPublished = false

    /// Permission state.
    private(set) var cameraPermissionGranted = false
    private(set) var microphonePermissionGranted = false

    // MARK: - Dependencies

    private let storyRepository: StoryRepositoryProtocol
    let cameraService: CameraService = .shared
    private let photoLibraryService: PhotoLibraryServiceProtocol = PhotoLibraryService.shared

    var isHardwareAvailable: Bool {
        cameraService.isHardwareAvailable
    }

    // MARK: - Init

    init(storyRepository: StoryRepositoryProtocol) {
        self.storyRepository = storyRepository
    }

    // MARK: - Permissions

    func checkPermissions() async {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)

        if cameraStatus == .notDetermined {
            cameraPermissionGranted = await AVCaptureDevice.requestAccess(for: .video)
        } else {
            cameraPermissionGranted = cameraStatus == .authorized
        }

        if micStatus == .notDetermined {
            microphonePermissionGranted = await AVCaptureDevice.requestAccess(for: .audio)
        } else {
            microphonePermissionGranted = micStatus == .authorized
        }

        if cameraPermissionGranted {
            if cameraService.isSessionConfigured {
                isFrontCamera = cameraService.isFrontFacing
                if cameraService.isRunning {
                    // Session already active & running; skip redundant configuration
                    await loadLatestGalleryThumbnail()
                    return
                }
            }
            _ = await cameraService.configureSession(isFront: isFrontCamera)
            cameraService.start()
        }

        // Fetch latest photo thumbnail for gallery shortcut
        await loadLatestGalleryThumbnail()
    }

    private func loadLatestGalleryThumbnail() async {
        guard latestGalleryThumbnail == nil else { return }
        if photoLibraryService.checkAuthorization() {
            let assets = await photoLibraryService.fetchAssets(in: nil, limit: 1)
            if let first = assets.first {
                self.latestGalleryThumbnail = await photoLibraryService.loadThumbnail(for: first.phAsset, targetSize: CGSize(width: 80, height: 80))
            }
        }
    }

    // MARK: - Camera Actions

    func capturePhoto() {
        Task {
            do {
                let data = try await cameraService.capturePhoto(isFlashOn: isFlashOn)
                capturedImageData = data
                isShowingPreview = true
                cameraService.stop()
            } catch {
                // If hardware capture fails (e.g. Simulator), create simulated photo
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1920))
                let image = renderer.image { ctx in
                    UIColor.darkGray.setFill()
                    ctx.fill(CGRect(x: 0, y: 0, width: 1080, height: 1920))
                }
                capturedImageData = image.jpegData(compressionQuality: 0.85)
                isShowingPreview = true
            }
        }
    }

    func startRecording() {
        isRecording = true
        cameraService.startRecording()
    }

    func stopRecording() {
        isRecording = false
        Task {
            do {
                let url = try await cameraService.stopRecording()
                capturedVideoURL = url
                isShowingPreview = true
                cameraService.stop()
            } catch {
                capturedVideoURL = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")
                isShowingPreview = true
            }
        }
    }

    func toggleCamera() {
        isFrontCamera.toggle()
        cameraService.switchCamera(isFront: isFrontCamera)
    }

    func toggleFlash() {
        isFlashOn.toggle()
        cameraService.setTorch(on: isFlashOn)
    }

    func retake() {
        capturedImageData = nil
        capturedVideoURL = nil
        stickers = []
        texts = []
        currentFilterIndex = 0
        isShowingPreview = false
        cameraService.start()
    }

    func loadFromGallery(data: Data, isVideo: Bool) {
        if isVideo {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("story_gallery_\(UUID().uuidString).mp4")
            try? data.write(to: tempURL)
            capturedVideoURL = tempURL
            capturedImageData = nil
        } else {
            capturedImageData = data
            capturedVideoURL = nil
        }
        isShowingPreview = true
        cameraService.stop()
    }

    func nextFilter() {
        currentFilterIndex = (currentFilterIndex + 1) % StoryFilter.allFilters.count
    }

    func previousFilter() {
        if currentFilterIndex == 0 {
            currentFilterIndex = StoryFilter.allFilters.count - 1
        } else {
            currentFilterIndex -= 1
        }
    }

    // MARK: - Publish

    func publishStory(isCloseFriendsOnly: Bool = false) async {
        guard hasCapturedMedia, !isPublishing else { return }
        isPublishing = true
        HUDManager.shared.showLoading(L10n.HUD.publishing)

        do {
            var mediaData = capturedImageData ?? Data()

            // If image story, bake filter, stickers & texts into final image
            if let baseImage = UIImage(data: mediaData) {
                var filtered = baseImage
                if currentFilter.filterId != "original",
                   let filter = FilterRegistry.filter(byId: currentFilter.filterId),
                   let ci = CIImage(image: baseImage) {
                    let outCI = FilterEngine.shared.apply(filter: filter, to: ci, intensity: 1.0)
                    if let rendered = FilterEngine.shared.renderToUIImage(outCI) {
                        filtered = rendered
                    }
                }

                let composite = CompositeImageRenderer.shared.render(
                    baseImage: filtered,
                    stickers: stickers,
                    texts: texts,
                    renderSize: CGSize(width: 1080, height: 1920)
                )

                if let jpeg = composite.jpegData(compressionQuality: 0.88) {
                    mediaData = jpeg
                }
            }

            let mediaType: StoryItem.MediaType = capturedVideoURL != nil ? .video : .image
            let duration: TimeInterval = capturedVideoURL != nil ? 15 : 5

            let story = try await storyRepository.createStory(
                mediaData: mediaData,
                type: mediaType,
                duration: duration
            )
            NotificationCenter.default.post(name: .didCreateStory, object: story)
            isPublished = true
            HUDManager.shared.showSuccess(L10n.HUD.published)
        } catch {
            HUDManager.shared.showError(error.userMessage)
        }

        isPublishing = false
    }

    // MARK: - Reset

    func reset() {
        capturedImageData = nil
        capturedVideoURL = nil
        stickers = []
        texts = []
        currentFilterIndex = 0
        isShowingPreview = false
        isPublished = false
    }
}
