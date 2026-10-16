//
//  CameraService.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import AVFoundation
import UIKit
import os

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

    // Configuration work happens on sessionQueue, while SwiftUI reads these
    // values on the main actor. Keep the observable state separate from the
    // capture graph and protect it from cross-thread stale reads.
    private let stateLock = OSAllocatedUnfairLock()
    private var sessionConfigured = false
    private var frontFacing = false
    private var wantsRunning = false
    private var interrupted = false

    var isSessionConfigured: Bool {
        stateLock.withLock { sessionConfigured }
    }

    var isFrontFacing: Bool {
        stateLock.withLock { frontFacing }
    }

    var isRunning: Bool {
        session.isRunning
    }

    private func setSessionConfigured(_ value: Bool) {
        stateLock.withLock { sessionConfigured = value }
    }

    private func setFrontFacing(_ value: Bool) {
        stateLock.withLock { frontFacing = value }
    }

    /// Whether real hardware camera is available (returns false on iOS Simulator).
    var isHardwareAvailable: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil ||
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil
    }

    private override init() {
        super.init()
        observeSessionLifecycle()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func observeSessionLifecycle() {
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(sessionWasInterrupted(_:)),
            name: AVCaptureSession.wasInterruptedNotification,
            object: session
        )
        center.addObserver(
            self,
            selector: #selector(sessionInterruptionEnded(_:)),
            name: AVCaptureSession.interruptionEndedNotification,
            object: session
        )
        center.addObserver(
            self,
            selector: #selector(sessionRuntimeError(_:)),
            name: AVCaptureSession.runtimeErrorNotification,
            object: session
        )
        center.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground(_:)),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func sessionWasInterrupted(_ notification: Notification) {
        stateLock.withLock {
            interrupted = true
        }
    }

    @objc private func sessionInterruptionEnded(_ notification: Notification) {
        let shouldResume = stateLock.withLock {
            interrupted = false
            return wantsRunning
        }
        if shouldResume { startSessionIfNeeded() }
    }

    @objc private func sessionRuntimeError(_ notification: Notification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        // Media services can be reset by the OS. The capture graph remains valid
        // in common cases; resume it only when the current UI still wants camera.
        if error.code == .mediaServicesWereReset { startSessionIfNeeded() }
    }

    @objc private func applicationDidEnterBackground(_ notification: Notification) {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    @objc private func applicationWillEnterForeground(_ notification: Notification) {
        startSessionIfNeeded()
    }

    // MARK: - Configuration

    func configureSession(isFront: Bool = false) async -> Bool {
        guard isHardwareAvailable else {
            return false
        }

        // Fast path: if already configured with matching camera position, return immediately!
        if isSessionConfigured && isFrontFacing == isFront && videoDeviceInput != nil {
            return true
        }

        return await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(returning: false)
                    return
                }

                // If session is already configured, only hot-swap the video input device!
                if self.isSessionConfigured, let currentInput = self.videoDeviceInput {
                    if self.isFrontFacing != isFront {
                        self.session.beginConfiguration()
                        self.session.removeInput(currentInput)
                        let position: AVCaptureDevice.Position = isFront ? .front : .back
                        if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
                           let newInput = try? AVCaptureDeviceInput(device: videoDevice),
                           self.session.canAddInput(newInput) {
                            self.session.addInput(newInput)
                            self.videoDeviceInput = newInput
                            self.setFrontFacing(isFront)
                        } else {
                            self.session.addInput(currentInput)
                        }
                        self.session.commitConfiguration()
                    }
                    continuation.resume(returning: true)
                    return
                }

                // Initial full session configuration
                self.session.beginConfiguration()
                self.session.sessionPreset = .high

                // Remove any stale inputs/outputs
                for input in self.session.inputs {
                    self.session.removeInput(input)
                }
                for output in self.session.outputs {
                    self.session.removeOutput(output)
                }

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
                    self.setFrontFacing(isFront)
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
                self.setSessionConfigured(true)
                continuation.resume(returning: true)
            }
        }
    }

    // MARK: - Session Controls

    func start() {
        guard isHardwareAvailable else { return }
        let isInterrupted = stateLock.withLock {
            wantsRunning = true
            return interrupted
        }
        guard !isInterrupted else { return }
        startSessionIfNeeded()
    }

    private func startSessionIfNeeded() {
        guard isHardwareAvailable else { return }
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stop() {
        guard isHardwareAvailable else { return }
        stateLock.withLock {
            wantsRunning = false
        }
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    // MARK: - Camera Switch

    func switchCamera(isFront: Bool) {
        guard isHardwareAvailable else {
            setFrontFacing(isFront)
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
                self.setFrontFacing(isFront)
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

                // Setup photo orientation
                if let connection = self.photoOutput.connection(with: .video) {
                    let targetAngle: CGFloat = self.isFrontFacing ? 270 : 90
                    if connection.isVideoRotationAngleSupported(targetAngle) {
                        connection.videoRotationAngle = targetAngle
                    } else if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                    }
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

            // Setup movie orientation
            if let connection = self.movieOutput.connection(with: .video) {
                let targetAngle: CGFloat = self.isFrontFacing ? 270 : 90
                if connection.isVideoRotationAngleSupported(targetAngle) {
                    connection.videoRotationAngle = targetAngle
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
            return generateMockVideoURL()
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

    func generateMockVideoURL() -> URL {
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("mock_reel_\(UUID().uuidString).mp4")
        try? FileManager.default.removeItem(at: outputURL)

        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            return outputURL
        }

        let width = 720
        let height = 1280
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        let attrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferCGImageCompatibilityKey as String: true
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: attrs)

        if writer.canAdd(input) {
            writer.add(input)
        }
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        let fps: Int32 = 30
        let durationSeconds = 3
        let totalFrames = fps * Int32(durationSeconds)

        for i in 0..<totalFrames {
            let frameTime = CMTime(value: Int64(i), timescale: fps)
            while !input.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.005)
            }
            var pixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferCreate(
                kCFAllocatorDefault,
                width,
                height,
                kCVPixelFormatType_32ARGB,
                attrs as CFDictionary,
                &pixelBuffer
            )
            if status == kCVReturnSuccess, let buffer = pixelBuffer {
                CVPixelBufferLockBaseAddress(buffer, [])
                let data = CVPixelBufferGetBaseAddress(buffer)
                let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
                let context = CGContext(
                    data: data,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                    space: rgbColorSpace,
                    bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
                )
                if let context {
                    let colors = [UIColor.systemPurple.cgColor, UIColor.systemIndigo.cgColor, UIColor.systemPink.cgColor]
                    if let gradient = CGGradient(colorsSpace: rgbColorSpace, colors: colors as CFArray, locations: [0.0, 0.5, 1.0]) {
                        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: CGFloat(height)), options: [])
                    }
                    UIGraphicsPushContext(context)
                    let text = "Instagram Reel\nClip Segment\n\(Date().formatted(date: .omitted, time: .standard))"
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .center
                    let textAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                        .foregroundColor: UIColor.white,
                        .paragraphStyle: paragraphStyle
                    ]
                    (text as NSString).draw(in: CGRect(x: 40, y: CGFloat(height) / 2.0 - 60, width: CGFloat(width) - 80, height: 120), withAttributes: textAttrs)
                    UIGraphicsPopContext()
                }
                CVPixelBufferUnlockBaseAddress(buffer, [])
                adaptor.append(buffer, withPresentationTime: frameTime)
            }
        }

        input.markAsFinished()
        let semaphore = DispatchSemaphore(value: 0)
        writer.finishWriting {
            semaphore.signal()
        }
        semaphore.wait()
        return outputURL
    }

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
