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
    }

    // MARK: - Camera Actions

    func capturePhoto() {
        // Simulated capture — real implementation uses AVCapturePhotoOutput
        // For now, create a placeholder
        capturedImageData = Data() // Placeholder
        isShowingPreview = true
    }

    func startRecording() {
        isRecording = true
        // Real implementation: start AVCaptureMovieFileOutput
    }

    func stopRecording() {
        isRecording = false
        capturedVideoURL = URL(string: "file:///tmp/story_video.mp4") // Placeholder
        isShowingPreview = true
    }

    func toggleCamera() {
        isFrontCamera.toggle()
    }

    func toggleFlash() {
        isFlashOn.toggle()
    }

    func retake() {
        capturedImageData = nil
        capturedVideoURL = nil
        isShowingPreview = false
    }

    // MARK: - Publish

    func publishStory() async {
        guard hasCapturedMedia, !isPublishing else { return }
        isPublishing = true

        do {
            let mediaData = capturedImageData ?? Data()
            let mediaType: StoryItem.MediaType = capturedVideoURL != nil ? .video : .image
            let duration: TimeInterval = capturedVideoURL != nil ? 15 : 5

            _ = try await storyRepository.createStory(
                mediaData: mediaData,
                type: mediaType,
                duration: duration
            )
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
