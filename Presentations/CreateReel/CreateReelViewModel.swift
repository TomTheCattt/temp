//
//  CreateReelViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import PhotosUI

// MARK: - CreateReelViewModel

@MainActor
@Observable
final class CreateReelViewModel {

    // MARK: - State

    /// Video picker item.
    var videoPickerItem: PhotosPickerItem?

    /// Selected video data.
    var selectedVideoData: Data?

    /// Video file URL for playback/review.
    var capturedVideoURL: URL?

    /// Recording state (for camera capture).
    var isRecording = false
    var isFrontCamera = true
    var isFlashOn = false
    var selectedDuration = "15s"

    /// Edit state.
    var caption: String = ""
    var selectedAudioName: String?

    /// Steps.
    var isShowingEditor = false

    /// Publishing.
    private(set) var isPublishing = false
    private(set) var isPublished = false

    let cameraService: CameraService = .shared

    // MARK: - Dependencies

    private let reelRepository: ReelRepositoryProtocol

    // MARK: - Init

    init(reelRepository: ReelRepositoryProtocol) {
        self.reelRepository = reelRepository
    }

    // MARK: - Camera Actions

    func setupCamera() async {
        _ = await cameraService.configureSession(isFront: isFrontCamera)
        cameraService.start()
    }

    func stopCamera() {
        cameraService.stop()
    }

    func toggleCamera() {
        isFrontCamera.toggle()
        cameraService.switchCamera(isFront: isFrontCamera)
    }

    func toggleFlash() {
        isFlashOn.toggle()
        cameraService.setTorch(on: isFlashOn)
    }

    func loadVideoFromPicker() async {
        guard let item = videoPickerItem else { return }

        if let data = try? await item.loadTransferable(type: Data.self) {
            selectedVideoData = data
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
            try? data.write(to: tempURL)
            capturedVideoURL = tempURL
            isShowingEditor = true
        }
    }

    func startRecording() {
        guard !isRecording else {
            stopRecording()
            return
        }
        isRecording = true
        cameraService.startRecording()
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        Task {
            do {
                let videoURL = try await cameraService.stopRecording()
                self.capturedVideoURL = videoURL
                if let data = try? Data(contentsOf: videoURL) {
                    self.selectedVideoData = data
                    self.isShowingEditor = true
                }
            } catch {
                HUDManager.shared.showError(error.localizedDescription)
            }
        }
    }

    func publish() async {
        guard let videoData = selectedVideoData, !isPublishing else { return }
        isPublishing = true
        HUDManager.shared.showLoading(L10n.HUD.publishing)

        do {
            let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = try await reelRepository.createReel(
                videoData: videoData,
                caption: trimmedCaption.isEmpty ? nil : trimmedCaption,
                audioTrackId: nil
            )
            isPublished = true
            HUDManager.shared.showSuccess(L10n.HUD.published)
        } catch {
            // Surfaced via the global HUD only.
            HUDManager.shared.showError(error.userMessage)
        }

        isPublishing = false
    }

    func reset() {
        videoPickerItem = nil
        selectedVideoData = nil
        capturedVideoURL = nil
        isRecording = false
        isShowingEditor = false
        caption = ""
        selectedAudioName = nil
        isPublished = false
    }
}
