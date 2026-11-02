//
//  CallVideoCaptureControllerTests.swift
//  InstagramTests
//
//  Created for testing CallVideoCaptureController video handling.
//

import XCTest
import AVFoundation
import CoreImage
@testable import Instagram

// MARK: - Mock AVCaptureSession

class MockAVCaptureSession {
    var isRunning = false
    var inputs: [MockAVCaptureInput] = []
    var outputs: [MockAVCaptureOutput] = []
    var sessionPreset: AVCaptureSession.Preset = .high
    var shouldFailAddInput = false
    var shouldFailAddOutput = false

    func addInput(_ input: MockAVCaptureInput) {
        if !shouldFailAddInput {
            inputs.append(input)
        }
    }

    func addOutput(_ output: MockAVCaptureOutput) {
        if !shouldFailAddOutput {
            outputs.append(output)
        }
    }

    func removeInput(_ input: MockAVCaptureInput) {
        inputs.removeAll { $0 === input }
    }

    func removeOutput(_ output: MockAVCaptureOutput) {
        outputs.removeAll { $0 === output }
    }

    func startRunning() {
        isRunning = true
    }

    func stopRunning() {
        isRunning = false
    }

    func beginConfiguration() {}
    func commitConfiguration() {}
}

// MARK: - Mock AVCaptureDevice

final class MockAVCaptureDevice: @unchecked Sendable {
    var uniqueID: String
    var position: AVCaptureDevice.Position
    var deviceType: AVCaptureDevice.DeviceType
    var formats: [AVCaptureDevice.Format] = []
    var activeFormat: AVCaptureDevice.Format?
    var activeVideoMinFrameDuration: CMTime = CMTime(value: 1, timescale: 30)
    var activeVideoMaxFrameDuration: CMTime = CMTime(value: 1, timescale: 30)
    var isFocusModeSupported: Bool = true
    var focusMode: AVCaptureDevice.FocusMode = .continuousAutoFocus
    var isExposureModeSupported: Bool = true
    var exposureMode: AVCaptureDevice.ExposureMode = .continuousAutoExposure
    var isWhiteBalanceModeSupported: Bool = true
    var whiteBalanceMode: AVCaptureDevice.WhiteBalanceMode = .continuousAutoWhiteBalance
    var isTorchModeSupported: Bool = false
    var torchMode: AVCaptureDevice.TorchMode = .off
    var torchLevel: Float = 1.0

    init(uniqueID: String, position: AVCaptureDevice.Position, deviceType: AVCaptureDevice.DeviceType) {
        self.uniqueID = uniqueID
        self.position = position
        self.deviceType = deviceType
    }

    func lockForConfiguration() throws {}
    func unlockForConfiguration() {}
}

// MARK: - Mock AVCaptureInput

class MockAVCaptureInput {
    let device: MockAVCaptureDevice?
    init(device: MockAVCaptureDevice? = nil) {
        self.device = device
    }
}

// MARK: - Mock AVCaptureOutput

class MockAVCaptureOutput {
    var videoSettings: [String: Any] = [:]
    var connection: MockAVCaptureConnection?
    var sampleBufferDelegate: MockSampleBufferDelegateProtocol?
    var sampleBufferCallbackQueue: DispatchQueue?
}

// MARK: - Mock AVCaptureConnection

class MockAVCaptureConnection {
    var isVideoMirrored = false
    var videoOrientation: AVCaptureVideoOrientation = .portrait
    var isVideoMirroringSupported = true
    var preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode = .standard
    var activeVideoMinFrameDuration: CMTime = CMTime(value: 1, timescale: 30)
    var activeVideoMaxFrameDuration: CMTime = CMTime(value: 1, timescale: 30)
}

// MARK: - Mock AVCaptureVideoDataOutput

class MockAVCaptureVideoDataOutput: MockAVCaptureOutput {
    var availableVideoPixelFormatTypes: [NSNumber] = [NSNumber(value: kCVPixelFormatType_32BGRA)]
    var availableVideoCodecTypes: [AVVideoCodecType] = [.h264]
}

// MARK: - Mock Sample Buffer Delegate Protocol

protocol MockSampleBufferDelegateProtocol: AnyObject {
    func captureOutput(_ output: MockAVCaptureVideoDataOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: MockAVCaptureConnection)
}

// MARK: - Testable Video Capture Controller

class TestableCallVideoCaptureController {
    var session: MockAVCaptureSession
    var currentDevice: MockAVCaptureDevice?
    var isSessionRunning = false
    var isFrontCamera = true
    var videoDimensions: CMVideoDimensions = CMVideoDimensions(width: 1280, height: 720)
    var frameRate: Int32 = 30
    var sampleBufferDelegate: MockSampleBufferDelegateProtocol?
    var sampleBufferQueue: DispatchQueue?
    var shouldFailSessionStart = false
    var shouldFailDeviceSwitch = false
    var syntheticGeneratorRunning = false
    var lastCapturedPixelBuffer: CVPixelBuffer?

    init() {
        self.session = MockAVCaptureSession()
        setupSession()
    }

    func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Create mock devices
        let frontDevice = MockAVCaptureDevice(
            uniqueID: "front_camera",
            position: .front,
            deviceType: .builtInWideAngleCamera
        )

        // Add front camera as default
        let input = MockAVCaptureInput(device: frontDevice)
        session.addInput(input)
        currentDevice = frontDevice
        isFrontCamera = true

        // Add video output
        let output = MockAVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        session.addOutput(output)

        session.commitConfiguration()
    }

    func startCapture() async throws {
        guard !shouldFailSessionStart else {
            throw NSError(domain: "VideoCapture", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to start capture"])
        }
        session.startRunning()
        isSessionRunning = true
    }

    func stopCapture() {
        session.stopRunning()
        isSessionRunning = false
    }

    func switchCamera() async throws {
        guard !shouldFailDeviceSwitch else {
            throw NSError(domain: "VideoCapture", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to switch camera"])
        }

        session.beginConfiguration()

        // Remove current input
        if let currentInput = session.inputs.first {
            session.removeInput(currentInput)
        }

        // Switch device
        isFrontCamera.toggle()
        let newDevice = MockAVCaptureDevice(
            uniqueID: isFrontCamera ? "front_camera" : "back_camera",
            position: isFrontCamera ? .front : .back,
            deviceType: .builtInWideAngleCamera
        )

        let newInput = MockAVCaptureInput(device: newDevice)
        session.addInput(newInput)
        currentDevice = newDevice

        session.commitConfiguration()
    }

    func setSampleBufferDelegate(_ delegate: MockSampleBufferDelegateProtocol?, queue: DispatchQueue) {
        sampleBufferDelegate = delegate
        sampleBufferQueue = queue

        if let output = session.outputs.first as? MockAVCaptureVideoDataOutput {
            output.sampleBufferDelegate = delegate
            output.sampleBufferCallbackQueue = queue
        }
    }

    func setVideoDimensions(_ dimensions: CMVideoDimensions) {
        videoDimensions = dimensions
    }

    func setFrameRate(_ fps: Int32) {
        frameRate = fps
        if let device = currentDevice {
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: fps)
            device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: fps)
        }
    }

    func startSyntheticGenerator() {
        syntheticGeneratorRunning = true
        // Generate test frames
        Task {
            while syntheticGeneratorRunning {
                generateSyntheticFrame()
                try? await Task.sleep(nanoseconds: 1_000_000_000 / UInt64(frameRate))
            }
        }
    }

    func stopSyntheticGenerator() {
        syntheticGeneratorRunning = false
    }

    private func generateSyntheticFrame() {
        // Create a simple test pattern pixel buffer
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary

        CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(videoDimensions.width),
            Int(videoDimensions.height),
            kCVPixelFormatType_32BGRA,
            attrs,
            &pixelBuffer
        )

        if let buffer = pixelBuffer {
            lastCapturedPixelBuffer = buffer
            // Deliver to delegate
            if let delegate = sampleBufferDelegate, let queue = sampleBufferQueue {
                queue.async {
                    // Create sample buffer from pixel buffer
                    var sampleBuffer: CMSampleBuffer?
                    var timingInfo = CMSampleTimingInfo(
                        duration: CMTime(value: 1, timescale: self.frameRate),
                        presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
                        decodeTimeStamp: CMTime.invalid
                    )
                    var formatDescription: CMVideoFormatDescription?
                    CMVideoFormatDescriptionCreateForImageBuffer(
                        allocator: kCFAllocatorDefault,
                        imageBuffer: buffer,
                        formatDescriptionOut: &formatDescription
                    )
                    if let formatDesc = formatDescription {
                        CMSampleBufferCreateReady(
                            allocator: kCFAllocatorDefault,
                            dataBuffer: nil,
                            formatDescription: formatDesc,
                            sampleCount: 1,
                            sampleTimingEntryCount: 1,
                            sampleTimingArray: &timingInfo,
                            sampleSizeEntryCount: 0,
                            sampleSizeArray: nil,
                            sampleBufferOut: &sampleBuffer
                        )
                        if let sb = sampleBuffer {
                            delegate.captureOutput(MockAVCaptureVideoDataOutput(), didOutput: sb, from: MockAVCaptureConnection())
                        }
                    }
                }
            }
        }
    }

    func pauseForBackground() {
        if isSessionRunning {
            stopCapture()
        }
        stopSyntheticGenerator()
    }

    func resumeForForeground() async throws {
        try await startCapture()
        startSyntheticGenerator()
    }

    func setMirroring(_ mirrored: Bool) {
        if let connection = session.outputs.first?.connection {
            connection.isVideoMirrored = mirrored
        }
    }

    func setVideoStabilizationMode(_ mode: AVCaptureVideoStabilizationMode) {
        if let connection = session.outputs.first?.connection {
            connection.preferredVideoStabilizationMode = mode
        }
    }

    func capturePhoto() async -> Data? {
        // Simulate photo capture
        guard let pixelBuffer = lastCapturedPixelBuffer else { return nil }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, cgImage, nil)
        CGImageDestinationFinalize(destination)

        return data as Data
    }
}

// MARK: - CallVideoCaptureControllerTests

final class CallVideoCaptureControllerTests: XCTestCase {

    var videoCapture: TestableCallVideoCaptureController!

    override func setUp() async throws {
        try await super.setUp()
        videoCapture = TestableCallVideoCaptureController()
    }

    override func tearDown() async throws {
        videoCapture.stopCapture()
        videoCapture.stopSyntheticGenerator()
        videoCapture = nil
        try await super.tearDown()
    }

    // MARK: - Hardware Capture Tests

    func testSetupSession_CreatesSessionWithFrontCamera() {
        XCTAssertNotNil(videoCapture.session)
        XCTAssertEqual(videoCapture.session.inputs.count, 1)
        XCTAssertEqual(videoCapture.session.outputs.count, 1)
        XCTAssertTrue(videoCapture.isFrontCamera)
        XCTAssertEqual(videoCapture.currentDevice?.position, .front)
    }

    func testStartCapture_ActivatesSession() async throws {
        try await videoCapture.startCapture()

        XCTAssertTrue(videoCapture.isSessionRunning)
        XCTAssertTrue(videoCapture.session.isRunning)
    }

    func testStartCapture_Failure_Throws() async throws {
        videoCapture.shouldFailSessionStart = true

        do {
            try await videoCapture.startCapture()
            XCTFail("Expected error")
        } catch {
            // Expected
        }
    }

    func testStopCapture_DeactivatesSession() async throws {
        try await videoCapture.startCapture()
        videoCapture.stopCapture()

        XCTAssertFalse(videoCapture.isSessionRunning)
        XCTAssertFalse(videoCapture.session.isRunning)
    }

    // MARK: - Camera Switch Tests

    func testSwitchCamera_ChangesToBackCamera() async throws {
        XCTAssertTrue(videoCapture.isFrontCamera)

        try await videoCapture.switchCamera()

        XCTAssertFalse(videoCapture.isFrontCamera)
        XCTAssertEqual(videoCapture.currentDevice?.position, .back)
    }

    func testSwitchCamera_TogglesBackToFront() async throws {
        try await videoCapture.switchCamera() // front -> back
        try await videoCapture.switchCamera() // back -> front

        XCTAssertTrue(videoCapture.isFrontCamera)
        XCTAssertEqual(videoCapture.currentDevice?.position, .front)
    }

    func testSwitchCamera_Failure_Throws() async throws {
        videoCapture.shouldFailDeviceSwitch = true

        do {
            try await videoCapture.switchCamera()
            XCTFail("Expected error")
        } catch {
            // Expected
        }
    }

    func testSwitchCamera_PreservesSessionRunning() async throws {
        try await videoCapture.startCapture()
        XCTAssertTrue(videoCapture.isSessionRunning)

        try await videoCapture.switchCamera()

        XCTAssertTrue(videoCapture.isSessionRunning)
    }

    // MARK: - Video Configuration Tests

    func testSetVideoDimensions_UpdatesDimensions() {
        let newDimensions = CMVideoDimensions(width: 1920, height: 1080)
        videoCapture.setVideoDimensions(newDimensions)

        XCTAssertEqual(videoCapture.videoDimensions.width, 1920)
        XCTAssertEqual(videoCapture.videoDimensions.height, 1080)
    }

    func testSetFrameRate_UpdatesFrameRate() {
        videoCapture.setFrameRate(60)

        XCTAssertEqual(videoCapture.frameRate, 60)
        XCTAssertEqual(videoCapture.currentDevice?.activeVideoMinFrameDuration, CMTime(value: 1, timescale: 60))
    }

    func testSetSampleBufferDelegate_AssignsDelegate() {
        let delegate = MockSampleBufferDelegate()
        let queue = DispatchQueue(label: "test.queue")

        videoCapture.setSampleBufferDelegate(delegate, queue: queue)

        XCTAssertNotNil(videoCapture.sampleBufferDelegate)
        XCTAssertNotNil(videoCapture.sampleBufferQueue)
    }

    // MARK: - Synthetic Generator Tests

    func testStartSyntheticGenerator_GeneratesFrames() async throws {
        videoCapture.startSyntheticGenerator()

        // Wait for a few frames
        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertTrue(videoCapture.syntheticGeneratorRunning)
        XCTAssertNotNil(videoCapture.lastCapturedPixelBuffer)
    }

    func testStopSyntheticGenerator_StopsGeneration() async throws {
        videoCapture.startSyntheticGenerator()
        try await Task.sleep(nanoseconds: 200_000_000)

        videoCapture.stopSyntheticGenerator()
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertFalse(videoCapture.syntheticGeneratorRunning)
    }

    func testSyntheticGenerator_CreatesValidPixelBuffer() async throws {
        videoCapture.startSyntheticGenerator()
        try await Task.sleep(nanoseconds: 200_000_000)

        guard let pixelBuffer = videoCapture.lastCapturedPixelBuffer else {
            XCTFail("No pixel buffer generated")
            return
        }

        XCTAssertEqual(CVPixelBufferGetWidth(pixelBuffer), 1280)
        XCTAssertEqual(CVPixelBufferGetHeight(pixelBuffer), 720)
        XCTAssertEqual(CVPixelBufferGetPixelFormatType(pixelBuffer), kCVPixelFormatType_32BGRA)
    }

    // MARK: - Background/Foreground Tests

    func testPauseForBackground_StopsCaptureAndGenerator() async throws {
        try await videoCapture.startCapture()
        videoCapture.startSyntheticGenerator()

        videoCapture.pauseForBackground()

        XCTAssertFalse(videoCapture.isSessionRunning)
        XCTAssertFalse(videoCapture.syntheticGeneratorRunning)
    }

    func testResumeForForeground_RestartsCaptureAndGenerator() async throws {
        try await videoCapture.startCapture()
        videoCapture.startSyntheticGenerator()

        videoCapture.pauseForBackground()
        try await videoCapture.resumeForForeground()

        XCTAssertTrue(videoCapture.isSessionRunning)
        XCTAssertTrue(videoCapture.syntheticGeneratorRunning)
    }

    func testBackgroundForeground_Cycle() async throws {
        try await videoCapture.startCapture()
        videoCapture.startSyntheticGenerator()

        // Background
        videoCapture.pauseForBackground()
        XCTAssertFalse(videoCapture.isSessionRunning)
        XCTAssertFalse(videoCapture.syntheticGeneratorRunning)

        // Foreground
        try await videoCapture.resumeForForeground()
        XCTAssertTrue(videoCapture.isSessionRunning)
        XCTAssertTrue(videoCapture.syntheticGeneratorRunning)

        // Background again
        videoCapture.pauseForBackground()
        XCTAssertFalse(videoCapture.isSessionRunning)
        XCTAssertFalse(videoCapture.syntheticGeneratorRunning)

        // Foreground again
        try await videoCapture.resumeForForeground()
        XCTAssertTrue(videoCapture.isSessionRunning)
        XCTAssertTrue(videoCapture.syntheticGeneratorRunning)
    }

    // MARK: - Mirroring Tests

    func testSetMirroring_UpdatesConnection() {
        videoCapture.setMirroring(true)

        if let connection = videoCapture.session.outputs.first?.connection {
            XCTAssertTrue(connection.isVideoMirrored)
        }

        videoCapture.setMirroring(false)

        if let connection = videoCapture.session.outputs.first?.connection {
            XCTAssertFalse(connection.isVideoMirrored)
        }
    }

    // MARK: - Video Stabilization Tests

    func testSetVideoStabilizationMode_UpdatesConnection() {
        videoCapture.setVideoStabilizationMode(.cinematicExtended)

        if let connection = videoCapture.session.outputs.first?.connection {
            XCTAssertEqual(connection.preferredVideoStabilizationMode, .cinematicExtended)
        }
    }

    // MARK: - Photo Capture Tests

    func testCapturePhoto_ReturnsImageData() async throws {
        videoCapture.startSyntheticGenerator()
        try await Task.sleep(nanoseconds: 200_000_000)

        let photoData = await videoCapture.capturePhoto()

        XCTAssertNotNil(photoData)
        XCTAssertGreaterThan(photoData?.count ?? 0, 0)
    }

    func testCapturePhoto_NoFrame_ReturnsNil() async throws {
        // Don't start generator
        let photoData = await videoCapture.capturePhoto()

        XCTAssertNil(photoData)
    }

    // MARK: - Concurrent Operations Tests

    func testConcurrentStartStop_DoesNotCrash() async throws {
        for _ in 0..<5 {
            try? await videoCapture.startCapture()
            videoCapture.stopCapture()
        }
        // Should not crash
    }

    func testConcurrentSwitchCamera_DoesNotCrash() async throws {
        try await videoCapture.startCapture()

        for _ in 0..<3 {
            try? await videoCapture.switchCamera()
        }
        // Should not crash
    }
}

// MARK: - Mock Sample Buffer Delegate

class MockSampleBufferDelegate: NSObject, MockSampleBufferDelegateProtocol {
    var receivedSampleBuffers: [CMSampleBuffer] = []

    func captureOutput(_ output: MockAVCaptureVideoDataOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: MockAVCaptureConnection) {
        receivedSampleBuffers.append(sampleBuffer)
    }
}