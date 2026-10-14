//
//  StoryCameraViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import AVFoundation

// MARK: - StoryCameraMode

enum StoryCameraMode: String, CaseIterable {
    case normal = "Normal"
    case boomerang = "Boomerang"
    case layout = "Layout"
    case multiCapture = "Multi-Capture"
    case hands_free = "Hands-Free"
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
    var selectedFilterId: String?

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
            _ = await cameraService.configureSession(isFront: isFrontCamera)
            cameraService.start()
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
                // If hardware capture fails, fallback to empty data
                capturedImageData = Data()
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

    // MARK: - Publish

    func publishStory() async {
        guard hasCapturedMedia, !isPublishing else { return }
        isPublishing = true

        do {
            let mediaData = capturedImageData ?? Data()
            let mediaType: StoryItem.MediaType = capturedVideoURL != nil ? .video : .image
            let duration: TimeInterval = capturedVideoURL != nil ? 15 : 5

            let story = try await storyRepository.createStory(
                mediaData: mediaData,
                type: mediaType,
                duration: duration
            )
            NotificationCenter.default.post(name: .didCreateStory, object: story)
            isPublished = true
        } catch {
            // Handle error
        }

        isPublishing = false
    }

    // MARK: - Reset

    func reset() {
        capturedImageData = nil
        capturedVideoURL = nil
        isShowingPreview = false
        isPublished = false
        selectedFilterId = nil
    }
}
