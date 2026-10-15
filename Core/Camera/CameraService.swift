//
//  CameraService.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import AVFoundation
import UIKit

// MARK: - CameraServiceError

enum CameraServiceError: LocalizedError {
    case deviceUnavailable
    case inputUnavailable
    case captureFailed
    case recordingFailed
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .deviceUnavailable: return "Camera device is not available on this device/simulator."
        case .inputUnavailable: return "Cannot configure camera inputs."
        case .captureFailed: return "Failed to capture photo."
        case .recordingFailed: return "Failed to record video."
        case .permissionDenied: return "Camera or microphone permission was denied."
        }
    }
}

// MARK: - CameraService

final class CameraService: NSObject, @unchecked Sendable {

    static let shared = CameraService()

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.instagram.camera.sessionQueue")
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var audioDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()

    private var photoContinuation: CheckedContinuation<Data, Error>?
    private var recordContinuation: CheckedContinuation<URL, Error>?

    private(set) var isSessionConfigured = false
    private(set) var isFrontFacing = false

    /// Whether real hardware camera is available (returns false on iOS Simulator).
    var isHardwareAvailable: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil ||
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil
    }

    private override init() {
        super.init()
    }

    // MARK: - Configuration

    func configureSession(isFront: Bool = false) async -> Bool {
        guard isHardwareAvailable else {
            return false
        }

        return await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(returning: false)
                    return
                }

                self.session.beginConfiguration()
                self.session.sessionPreset = .high

                // Video input
                let position: AVCaptureDevice.Position = isFront ? .front : .back
                guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
                      let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                    self.session.commitConfiguration()
                    continuation.resume(returning: false)
                    return
                }

                if self.session.canAddInput(videoInput) {
                    self.session.addInput(videoInput)
                    self.videoDeviceInput = videoInput
                    self.isFrontFacing = isFront
                }

                // Audio input
                if let audioDevice = AVCaptureDevice.default(for: .audio),
                   let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
                   self.session.canAddInput(audioInput) {
                    self.session.addInput(audioInput)
                    self.audioDeviceInput = audioInput
                }

                // Photo output
                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                    if #available(iOS 16.0, *) {
                        // High-resolution photo capture is default in iOS 16+
                    } else {
                        self.photoOutput.isHighResolutionCaptureEnabled = true
                    }
                }

                // Movie output
                if self.session.canAddOutput(self.movieOutput) {
                    self.session.addOutput(self.movieOutput)
                }

                self.session.commitConfiguration()
                self.isSessionConfigured = true
                continuation.resume(returning: true)
            }
        }
    }

    // MARK: - Session Controls

    func start() {
        guard isHardwareAvailable else { return }
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stop() {
        guard isHardwareAvailable else { return }
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    // MARK: - Camera Switch

    func switchCamera(isFront: Bool) {
        guard isHardwareAvailable else {
            isFrontFacing = isFront
            return
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()

            if let currentInput = self.videoDeviceInput {
                self.session.removeInput(currentInput)
            }

            let position: AVCaptureDevice.Position = isFront ? .front : .back
            if let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
               let newInput = try? AVCaptureDeviceInput(device: newDevice),
               self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.videoDeviceInput = newInput
                self.isFrontFacing = isFront
            }

            self.session.commitConfiguration()
        }
    }

    // MARK: - Torch / Flash

    func setTorch(on: Bool) {
        guard let device = videoDeviceInput?.device, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            // Ignore torch configuration failure
        }
    }

    // MARK: - Capture Photo

    func capturePhoto(isFlashOn: Bool = false) async throws -> Data {
        guard isHardwareAvailable else {
            // Fallback mock image for simulator
            return generateMockImageData()
        }

        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraServiceError.captureFailed)
                    return
                }

                self.photoContinuation = continuation

                let settings = AVCapturePhotoSettings()
                if self.videoDeviceInput?.device.hasFlash == true {
                    settings.flashMode = isFlashOn ? .on : .off
                }
                Task { @MainActor in
                    self.photoOutput.capturePhoto(with: settings, delegate: self)
                }
            }
        }
    }

    // MARK: - Video Recording

    func startRecording() {
        guard isHardwareAvailable else { return }
        sessionQueue.async { [weak self] in
            guard let self, !self.movieOutput.isRecording else { return }

            let tempDir = FileManager.default.temporaryDirectory
            let outputURL = tempDir.appendingPathComponent("story_recording_\(UUID().uuidString).mp4")
            try? FileManager.default.removeItem(at: outputURL)

            // Setup orientation
            if let connection = self.movieOutput.connection(with: .video) {
                if #available(iOS 17.0, *) {
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
                } else if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }

            Task { @MainActor in
                self.movieOutput.startRecording(to: outputURL, recordingDelegate: self)
            }
        }
    }

    func stopRecording() async throws -> URL {
        guard isHardwareAvailable else {
            // Fallback video URL
            return URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")!
        }

        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraServiceError.recordingFailed)
                    return
                }

                self.recordContinuation = continuation

                if self.movieOutput.isRecording {
                    self.movieOutput.stopRecording()
                } else {
                    continuation.resume(throwing: CameraServiceError.recordingFailed)
                }
            }
        }
    }

    // MARK: - Mock Generator for Simulator

    func generateMockImageData() -> Data {
        let size = CGSize(width: 1080, height: 1920)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            // Gradient background
            let colors = [UIColor.systemPurple.cgColor, UIColor.systemPink.cgColor, UIColor.systemOrange.cgColor]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 0.5, 1.0])!
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])

            let text = "Story Camera Snapshot\n\(Date().formatted(date: .omitted, time: .standard))"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attrs)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attrs)
        }
        return image.jpegData(compressionQuality: 0.9) ?? Data()
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            self.photoContinuation?.resume(throwing: error)
        } else if let data = photo.fileDataRepresentation() {
            self.photoContinuation?.resume(returning: data)
        } else {
            self.photoContinuation?.resume(throwing: CameraServiceError.captureFailed)
        }
        self.photoContinuation = nil
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        if let error {
            self.recordContinuation?.resume(throwing: error)
        } else {
            self.recordContinuation?.resume(returning: outputFileURL)
        }
        self.recordContinuation = nil
    }
}
