//
//  PostCameraViewModel.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import Foundation
import AVKit

// MARK: - PostCameraViewModel

@MainActor
@Observable
final class PostCameraViewModel {
    var isFrontCamera = false
    var isFlashOn = false
    var isRecording = false
    var capturedPreviewData: Data?
    var capturedVideoURL: URL?
    var isVideo = false

    let cameraService: CameraService = .shared

    var isHardwareAvailable: Bool {
        cameraService.isHardwareAvailable
    }

    func setupSession() async {
        _ = await cameraService.configureSession(isFront: isFrontCamera)
        cameraService.start()
    }

    func stopSession() {
        cameraService.stop()
    }

    func toggleFlash() {
        isFlashOn.toggle()
        cameraService.setTorch(on: isFlashOn)
    }

    func toggleCamera() {
        isFrontCamera.toggle()
        cameraService.switchCamera(isFront: isFrontCamera)
    }

    func capturePhoto() {
        Task {
            do {
                let photoData = try await cameraService.capturePhoto(isFlashOn: isFlashOn)
                self.capturedPreviewData = photoData
                self.capturedVideoURL = nil
                self.isVideo = false
            } catch {
                HUDManager.shared.showError(error.localizedDescription)
            }
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
                if let videoData = try? Data(contentsOf: videoURL) {
                    self.capturedPreviewData = videoData
                    self.isVideo = true
                }
            } catch {
                HUDManager.shared.showError(error.localizedDescription)
            }
        }
    }

    func retake() {
        capturedPreviewData = nil
        capturedVideoURL = nil
        isVideo = false
    }
}