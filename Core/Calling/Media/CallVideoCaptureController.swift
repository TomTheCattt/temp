//
//  CallVideoCaptureController.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
@preconcurrency import AVFoundation
import CoreMedia
import CoreGraphics
import Combine

#if canImport(UIKit)
import UIKit
#endif

// MARK: - CallVideoCaptureController

/// Dedicated native camera capture and video frame controller.
/// Completely isolated from Story/Feed CameraService to prevent session collisions.
/// Features a zero-alloc CVPixelBufferPool high-fidelity synthetic generator for iOS Simulator.
@MainActor
final class CallVideoCaptureController: @unchecked Sendable {

    // MARK: - Singleton

    static let shared = CallVideoCaptureController()

    // MARK: - Publishers

    /// Emits local camera or simulator CMSampleBuffers for Picture-in-Picture preview.
    /// Automatically replays the last captured frame to new subscribers (e.g. PiP remounting) to prevent black flicker.
    nonisolated var localSampleBufferPublisher: AnyPublisher<CMSampleBuffer, Never> {
        Deferred { [weak self] () -> AnyPublisher<CMSampleBuffer, Never> in
            guard let self else {
                return Empty().eraseToAnyPublisher()
            }
            if let last = self.lastSampleBuffer {
                return self.localSampleBufferSubject
                    .prepend(last)
                    .eraseToAnyPublisher()
            } else {
                return self.localSampleBufferSubject.eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }

    /// Emits remote partner or synthetic loopback CMSampleBuffers for full-screen view.
    nonisolated var remoteSampleBufferPublisher: AnyPublisher<CMSampleBuffer, Never> {
        remoteSampleBufferSubject.eraseToAnyPublisher()
    }

    private nonisolated let localSampleBufferSubject = PassthroughSubject<CMSampleBuffer, Never>()
    private nonisolated let remoteSampleBufferSubject = PassthroughSubject<CMSampleBuffer, Never>()
    private nonisolated(unsafe) var lastSampleBuffer: CMSampleBuffer?

    /// Replays the last captured frame to local subscribers if available.
    nonisolated func replayLastSampleBuffer() {
        if let last = lastSampleBuffer {
            localSampleBufferSubject.send(last)
        }
    }

    // MARK: - Hardware Capture Properties

    private nonisolated(unsafe) let captureSession = AVCaptureSession()
    private nonisolated(unsafe) let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "com.instagram.call.videoQueue", qos: .userInteractive)
    private let sessionQueue = DispatchQueue(label: "com.instagram.call.videoSessionQueue")
    private var currentVideoInput: AVCaptureDeviceInput?
    private var isFrontFacing: Bool = true

    // Delegate bridge
    private lazy var delegateHandler = VideoDataOutputDelegateHandler { [weak self] sampleBuffer in
        self?.handleHardwareVideoFrame(sampleBuffer)
    }

    // MARK: - State Management

    private var isRunning: Bool = false
    private var isUsingSyntheticGenerator: Bool = false
    private var syntheticLoopTask: Task<Void, Never>?

    // MARK: - Synthetic Generator

    private let syntheticGenerator = SyntheticFrameGenerator()

    // MARK: - Init & Deinit

    init() {}

    deinit {
        syntheticLoopTask?.cancel()
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    // MARK: - Public API

    /// Starts video capture. If on iOS Simulator or hardware camera is absent, starts synthetic generator.
    func startVideo(isFront: Bool) async throws {
        guard !isRunning else { return }
        self.isFrontFacing = isFront

        #if targetEnvironment(simulator)
        startSyntheticGenerator(isFront: isFront)
        isRunning = true
        #else
        // Check Camera permission
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authStatus != .authorized {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted {
                AppLogger.general.notice("Camera access not granted, falling back to synthetic generator")
                startSyntheticGenerator(isFront: isFront)
                isRunning = true
                return
            }
        }

        // Check hardware camera availability
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: isFront ? .front : .back) {
            do {
                try configureHardwareSession(device: device, isFront: isFront)
                let session = self.captureSession
                sessionQueue.async {
                    session.startRunning()
                }
                // Always start remote synthetic feed loop until remote peer connects
                startRemoteSyntheticFeed()
                isRunning = true
            } catch {
                AppLogger.general.notice("Hardware camera configure failed, falling back to synthetic generator: \(error.localizedDescription)")
                startSyntheticGenerator(isFront: isFront)
                isRunning = true
            }
        } else {
            startSyntheticGenerator(isFront: isFront)
            isRunning = true
        }
        #endif
    }

    /// Stops video capture session and synthetic generator loops.
    func stopVideo() {
        guard isRunning else { return }

        syntheticLoopTask?.cancel()
        syntheticLoopTask = nil
        isUsingSyntheticGenerator = false

        let session = self.captureSession
        sessionQueue.async {
            guard session.isRunning else { return }
            session.stopRunning()
        }

        isRunning = false
    }

    /// Switches camera orientation (front/back).
    func switchCamera(isFront: Bool) async {
        guard isRunning else { return }
        self.isFrontFacing = isFront

        #if targetEnvironment(simulator)
        syntheticGenerator.updateCameraFacing(isFront: isFront)
        #else
        guard !isUsingSyntheticGenerator else {
            syntheticGenerator.updateCameraFacing(isFront: isFront)
            return
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.captureSession.beginConfiguration()
            defer { self.captureSession.commitConfiguration() }

            if let currentInput = self.currentVideoInput {
                self.captureSession.removeInput(currentInput)
                self.currentVideoInput = nil
            }

            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: isFront ? .front : .back),
               let newInput = try? AVCaptureDeviceInput(device: device),
               self.captureSession.canAddInput(newInput) {
                self.captureSession.addInput(newInput)
                self.currentVideoInput = newInput
                self.updateVideoConnection(isFront: isFront)
            }
        }
        #endif
    }

    // MARK: - Hardware Capture Configuration

    private func configureHardwareSession(device: AVCaptureDevice, isFront: Bool) throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        // Session Preset: Dedicated 720p 30fps
        if captureSession.canSetSessionPreset(.hd1280x720) {
            captureSession.sessionPreset = .hd1280x720
        }

        // Configure Input
        if let current = currentVideoInput {
            captureSession.removeInput(current)
        }
        let input = try AVCaptureDeviceInput(device: device)
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
            currentVideoInput = input
        }

        // Configure Output (NV12 BiPlanar for hardware zero-copy)
        if captureSession.outputs.isEmpty && captureSession.canAddOutput(videoOutput) {
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
            ]
            videoOutput.setSampleBufferDelegate(delegateHandler, queue: videoQueue)
            captureSession.addOutput(videoOutput)
        }

        updateVideoConnection(isFront: isFront)
    }

    private func updateVideoConnection(isFront: Bool) {
        guard let connection = videoOutput.connection(with: .video) else { return }

        if #available(iOS 17.0, *) {
            if connection.isVideoRotationAngleSupported(isFront ? 270 : 90) {
                connection.videoRotationAngle = isFront ? 270 : 90
            }
        } else {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }

        // Mirror front camera only, NEVER mirror back camera
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = isFront
        }
    }

    private nonisolated func handleHardwareVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        autoreleasepool {
            lastSampleBuffer = sampleBuffer
            localSampleBufferSubject.send(sampleBuffer)
        }
    }

    private nonisolated func dispatchSyntheticLocalFrame(_ sampleBuffer: CMSampleBuffer) {
        autoreleasepool {
            lastSampleBuffer = sampleBuffer
            localSampleBufferSubject.send(sampleBuffer)
        }
    }

    // MARK: - High-Fidelity Synthetic Generator

    private func startSyntheticGenerator(isFront: Bool) {
        isUsingSyntheticGenerator = true
        syntheticGenerator.updateCameraFacing(isFront: isFront)
        syntheticLoopTask?.cancel()

        let remoteSubject = self.remoteSampleBufferSubject
        let generator = self.syntheticGenerator

        syntheticLoopTask = Task.detached(priority: .userInitiated) { [weak self] in
            let clock = ContinuousClock()
            var nextTick = clock.now
            let frameInterval = Duration.milliseconds(33) // 30 FPS

            while !Task.isCancelled {
                autoreleasepool {
                    generator.renderAndDispatchSyntheticFrames(
                        onLocalFrame: { [weak self] sample in
                            self?.dispatchSyntheticLocalFrame(sample)
                        },
                        remoteSubject: remoteSubject
                    )
                }

                nextTick += frameInterval
                try? await clock.sleep(until: nextTick)
            }
        }
    }

    private func startRemoteSyntheticFeed() {
        syntheticLoopTask?.cancel()

        let remoteSubject = self.remoteSampleBufferSubject
        let generator = self.syntheticGenerator

        syntheticLoopTask = Task.detached(priority: .userInitiated) {
            let clock = ContinuousClock()
            var nextTick = clock.now
            let frameInterval = Duration.milliseconds(33) // 30 FPS

            while !Task.isCancelled {
                autoreleasepool {
                    generator.renderAndDispatchRemoteFeedFrame(remoteSubject: remoteSubject)
                }

                nextTick += frameInterval
                try? await clock.sleep(until: nextTick)
            }
        }
    }
}

// MARK: - SyntheticFrameGenerator

private final class SyntheticFrameGenerator: @unchecked Sendable {

    private let frameWidth = 720
    private let frameHeight = 1280
    nonisolated(unsafe) private var pixelBufferPool: CVPixelBufferPool?
    nonisolated(unsafe) private var frameIndex: Int = 0
    nonisolated(unsafe) private var isFrontCamera: Bool = true
    private let lock = NSLock()

    nonisolated init() {
        setupPixelBufferPool()
    }

    nonisolated func updateCameraFacing(isFront: Bool) {
        lock.lock()
        self.isFrontCamera = isFront
        lock.unlock()
    }

    nonisolated private func setupPixelBufferPool() {
        let poolAttributes: [CFString: Any] = [
            kCVPixelBufferPoolMinimumBufferCountKey: 3
        ]
        let bufferAttributes: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA),
            kCVPixelBufferWidthKey: frameWidth,
            kCVPixelBufferHeightKey: frameHeight,
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as [CFString: Any]
        ]

        var pool: CVPixelBufferPool?
        let status = CVPixelBufferPoolCreate(
            kCFAllocatorDefault,
            poolAttributes as CFDictionary,
            bufferAttributes as CFDictionary,
            &pool
        )
        if status == kCVReturnSuccess {
            self.pixelBufferPool = pool
        }
    }

    nonisolated func renderAndDispatchSyntheticFrames(
        onLocalFrame: (CMSampleBuffer) -> Void,
        remoteSubject: PassthroughSubject<CMSampleBuffer, Never>
    ) {
        guard let pool = pixelBufferPool else { return }

        lock.lock()
        frameIndex += 1
        let currentFrame = frameIndex
        let isFront = isFrontCamera
        lock.unlock()

        if let localSample = generateCanvasSampleBuffer(
            pool: pool,
            isRemote: false,
            isFront: isFront,
            frameIndex: currentFrame
        ) {
            onLocalFrame(localSample)
        }

        if let remoteSample = generateCanvasSampleBuffer(
            pool: pool,
            isRemote: true,
            isFront: true,
            frameIndex: currentFrame
        ) {
            remoteSubject.send(remoteSample)
        }
    }

    nonisolated func renderAndDispatchRemoteFeedFrame(
        remoteSubject: PassthroughSubject<CMSampleBuffer, Never>
    ) {
        guard let pool = pixelBufferPool else { return }

        lock.lock()
        frameIndex += 1
        let currentFrame = frameIndex
        lock.unlock()

        if let remoteSample = generateCanvasSampleBuffer(
            pool: pool,
            isRemote: true,
            isFront: true,
            frameIndex: currentFrame
        ) {
            remoteSubject.send(remoteSample)
        }
    }

    nonisolated private func generateCanvasSampleBuffer(
        pool: CVPixelBufferPool,
        isRemote: Bool,
        isFront: Bool,
        frameIndex: Int
    ) -> CMSampleBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: baseAddress,
            width: frameWidth,
            height: frameHeight,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else { return nil }

        // 1. Draw smooth dynamic gradient background
        let phase = Double(frameIndex) * 0.03
        let color1: CGColor
        let color2: CGColor

        if isRemote {
            // Dark luxury violet-navy gradient
            let r = 0.08 + 0.02 * sin(phase)
            let g = 0.09 + 0.02 * cos(phase)
            let b = 0.16 + 0.03 * sin(phase * 0.7)
            color1 = CGColor(red: r, green: g, blue: b, alpha: 1.0)
            color2 = CGColor(red: 0.03, green: 0.04, blue: 0.06, alpha: 1.0)
        } else {
            // Dark modern emerald-slate gradient for local preview
            let r = 0.06 + 0.02 * cos(phase)
            let g = 0.12 + 0.03 * sin(phase)
            let b = 0.15 + 0.02 * cos(phase * 0.8)
            color1 = CGColor(red: r, green: g, blue: b, alpha: 1.0)
            color2 = CGColor(red: 0.04, green: 0.05, blue: 0.07, alpha: 1.0)
        }

        if let gradient = CGGradient(colorsSpace: colorSpace, colors: [color1, color2] as CFArray, locations: [0.0, 1.0]) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: frameHeight),
                options: []
            )
        }

        // 2. Draw animated radar concentric rings in center
        let centerX = CGFloat(frameWidth) / 2.0
        let centerY = CGFloat(frameHeight) / 2.0
        let pulseRadius = 140.0 + 30.0 * sin(phase * 2.0)

        context.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25))
        context.setLineWidth(3.0)
        context.addArc(center: CGPoint(x: centerX, y: centerY), radius: pulseRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        context.strokePath()

        context.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.50))
        context.setLineWidth(2.0)
        context.addArc(center: CGPoint(x: centerX, y: centerY), radius: 80.0, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        context.strokePath()

        // 3. Central Avatar Placeholder Core
        context.setFillColor(CGColor(red: 0.25, green: 0.28, blue: 0.35, alpha: 0.85))
        context.addArc(center: CGPoint(x: centerX, y: centerY), radius: 60.0, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        context.fillPath()

        // Wrap into CMSampleBuffer with presentation timestamp
        var formatDesc: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: buffer,
            formatDescriptionOut: &formatDesc
        )
        guard let format = formatDesc else { return nil }

        let ptsSeconds = Double(frameIndex) / 30.0
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: CMTime(seconds: ptsSeconds, preferredTimescale: 600),
            decodeTimeStamp: .invalid
        )

        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: buffer,
            formatDescription: format,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )

        return sampleBuffer
    }
}

// MARK: - VideoDataOutputDelegateHandler

private final class VideoDataOutputDelegateHandler: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    private let onFrame: @Sendable (CMSampleBuffer) -> Void

    init(onFrame: @escaping @Sendable (CMSampleBuffer) -> Void) {
        self.onFrame = onFrame
        super.init()
    }

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        onFrame(sampleBuffer)
    }
}
