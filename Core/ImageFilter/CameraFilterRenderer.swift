//
//  CameraFilterRenderer.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import AVFoundation
import CoreImage
import Metal
import MetalKit
import UIKit
import Combine

// MARK: - CameraFilterRenderer

/// Manages AVCaptureSession and renders filtered camera frames in real-time via Metal.
/// Uses FilterEngine's shared CIContext to avoid creating duplicate GPU resources.
///
/// Architecture:
///   AVCaptureSession → CMSampleBuffer → CIImage → apply filter → render to MTKView
///
/// Performance notes:
/// - Renders at camera resolution (not downscaled) for sharp preview
/// - CIContext.render(to: MTLTexture) avoids CPU roundtrip
/// - Single CIContext reused (no per-frame allocation)
/// - Filter is applied lazily as CIImage graph (no extra copies)
final class CameraFilterRenderer: NSObject, ObservableObject, @unchecked Sendable {

    // MARK: - Published State

    @Published var isRunning = false
    @Published var currentFilter: ImageFilter = OriginalFilter()
    @Published var filterIntensity: Float = 1.0
    @Published var currentPosition: AVCaptureDevice.Position = .back

    // MARK: - Metal

    let metalDevice: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let ciContext: CIContext
    private var currentDrawable: CAMetalDrawable?

    // MARK: - AVCapture

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.instagram.camera.session")
    private let renderQueue = DispatchQueue(label: "com.instagram.camera.render", qos: .userInteractive)

    // MARK: - Rendering target

    /// Set this to the MTKView that will display the filtered camera feed.
    weak var metalView: MTKView? {
        didSet {
            metalView?.device = metalDevice
            metalView?.framebufferOnly = false
            metalView?.isPaused = true           // We drive draws manually
            metalView?.enableSetNeedsDisplay = false
        }
    }

    // MARK: - State

    private var latestCIImage: CIImage?
    private var isConfigured = false

    // MARK: - Init

    override init() {
        let engine = FilterEngine.shared
        self.metalDevice = engine.metalDevice
        self.commandQueue = engine.metalDevice.makeCommandQueue()!
        self.ciContext = engine.ciContext
        super.init()
    }

    // MARK: - Session Control

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if !self.isConfigured {
                self.configureSession()
            }

            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                DispatchQueue.main.async { self.isRunning = true }
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                DispatchQueue.main.async { self.isRunning = false }
            }
        }
    }

    // MARK: - Switch Camera

    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            let newPosition: AVCaptureDevice.Position = self.currentPosition == .back ? .front : .back

            self.captureSession.beginConfiguration()

            // Remove existing input
            if let currentInput = self.captureSession.inputs.first as? AVCaptureDeviceInput {
                self.captureSession.removeInput(currentInput)
            }

            // Add new input
            guard let device = self.cameraDevice(for: newPosition),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                self.captureSession.commitConfiguration()
                return
            }

            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
                DispatchQueue.main.async { self.currentPosition = newPosition }
            }

            self.captureSession.commitConfiguration()
        }
    }

    // MARK: - Capture Still Photo (with filter applied)

    func captureFilteredPhoto() -> UIImage? {
        guard let ciImage = latestCIImage else { return nil }

        let filtered = FilterEngine.shared.apply(
            filter: currentFilter,
            to: ciImage,
            intensity: filterIntensity
        )

        return FilterEngine.shared.renderToUIImage(filtered)
    }

    // MARK: - Private: Configure Session

    private func configureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

        // Camera input
        guard let device = cameraDevice(for: currentPosition),
              let input = try? AVCaptureDeviceInput(device: device) else {
            captureSession.commitConfiguration()
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        // Video output
        videoOutput.setSampleBufferDelegate(self, queue: renderQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        // Fix orientation
        if let connection = videoOutput.connection(with: .video) {
            connection.videoRotationAngle = 90
            if currentPosition == .front {
                connection.isVideoMirrored = true
            }
        }

        captureSession.commitConfiguration()
        isConfigured = true
    }

    private func cameraDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraFilterRenderer: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Create CIImage from camera frame (zero-copy on Metal)
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Apply filter (lazy — builds CIImage graph, no actual rendering yet)
        let filtered = FilterEngine.shared.apply(
            filter: currentFilter,
            to: ciImage,
            intensity: filterIntensity
        )

        // Store for photo capture
        latestCIImage = ciImage

        // Render to Metal view
        renderToMetalView(filtered)
    }

    // MARK: - Render to MTKView

    private func renderToMetalView(_ ciImage: CIImage) {
        guard let metalView,
              let drawable = metalView.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }

        let texture = drawable.texture
        let drawableSize = CGSize(width: texture.width, height: texture.height)

        // Scale CIImage to fit the drawable
        let scaleX = drawableSize.width / ciImage.extent.width
        let scaleY = drawableSize.height / ciImage.extent.height
        let scale = max(scaleX, scaleY) // Aspect fill

        let scaledImage = ciImage
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Center crop to drawable bounds
        let xOffset = (scaledImage.extent.width - drawableSize.width) / 2
        let yOffset = (scaledImage.extent.height - drawableSize.height) / 2
        let cropRect = CGRect(
            x: scaledImage.extent.origin.x + xOffset,
            y: scaledImage.extent.origin.y + yOffset,
            width: drawableSize.width,
            height: drawableSize.height
        )
        let croppedImage = scaledImage.cropped(to: cropRect)

        // Render directly to Metal texture (no CPU roundtrip)
        let renderBounds = CGRect(origin: .zero, size: drawableSize)
        ciContext.render(
            croppedImage,
            to: texture,
            commandBuffer: commandBuffer,
            bounds: renderBounds,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// MARK: - CameraFilterView (SwiftUI wrapper)

import SwiftUI

/// SwiftUI wrapper for the real-time filtered camera preview.
struct CameraFilterView: UIViewRepresentable {

    @ObservedObject var renderer: CameraFilterRenderer

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = renderer.metalDevice
        mtkView.framebufferOnly = false
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = false
        mtkView.contentMode = .scaleAspectFill
        mtkView.clipsToBounds = true
        renderer.metalView = mtkView
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // Filter changes are handled reactively via CameraFilterRenderer
    }
}
