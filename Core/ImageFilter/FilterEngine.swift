//
//  FilterEngine.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Metal
import UIKit

// MARK: - FilterEngine

/// Central rendering engine for image filters.
/// Uses a single Metal-backed CIContext for all rendering — never create multiple contexts.
final class FilterEngine: Sendable {

    static let shared = FilterEngine()

    // MARK: - Metal + CIContext (singleton)

    let metalDevice: MTLDevice
    let ciContext: CIContext
    private let commandQueue: MTLCommandQueue

    private init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("[FilterEngine] Metal is not supported on this device.")
        }
        guard let queue = device.makeCommandQueue() else {
            fatalError("[FilterEngine] Failed to create Metal command queue.")
        }

        self.metalDevice = device
        self.commandQueue = queue

        // CIContext options optimized for real-time and batch rendering
        self.ciContext = CIContext(
            mtlCommandQueue: queue,
            options: [
                .cacheIntermediates: false,    // Don't cache — each frame is different
                .priorityRequestLow: false,    // High priority for responsive UI
                .highQualityDownsample: false,  // Speed over quality for previews
                .name: "InstagramFilterEngine"
            ]
        )
    }

    // MARK: - Apply Filter to CIImage

    /// Apply a filter to a CIImage. This is the cheapest operation — no pixel rendering yet.
    /// Rendering only happens when you call `renderToUIImage` or draw to a Metal view.
    func apply(filter: ImageFilter, to image: CIImage, intensity: Float = 1.0) -> CIImage {
        guard intensity > 0 else { return image }

        let filtered = filter.apply(to: image)

        // Blend original and filtered based on intensity
        if intensity < 1.0 {
            return blendImages(background: image, foreground: filtered, intensity: intensity)
        }

        return filtered
    }

    // MARK: - Render to UIImage

    /// Render a CIImage to UIImage. Use for final export or static previews.
    /// This is the expensive operation — triggers actual GPU work.
    func renderToUIImage(_ ciImage: CIImage, targetSize: CGSize? = nil) -> UIImage? {
        let imageToRender: CIImage
        if let targetSize {
            let scale = min(targetSize.width / ciImage.extent.width,
                           targetSize.height / ciImage.extent.height)
            imageToRender = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        } else {
            imageToRender = ciImage
        }

        guard let cgImage = ciContext.createCGImage(imageToRender, from: imageToRender.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    /// Render at a specific size — useful for thumbnails.
    func renderThumbnail(_ ciImage: CIImage, size: CGSize = CGSize(width: 150, height: 150)) -> UIImage? {
        let scale = min(size.width / ciImage.extent.width,
                       size.height / ciImage.extent.height)
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let cropped = scaled.cropped(to: CGRect(origin: .zero, size: size))

        guard let cgImage = ciContext.createCGImage(cropped, from: cropped.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Render to CGImage (for pixel buffer / video frame)

    func renderToCGImage(_ ciImage: CIImage) -> CGImage? {
        ciContext.createCGImage(ciImage, from: ciImage.extent)
    }

    // MARK: - Render to Pixel Buffer (for camera preview / video export)

    func render(_ ciImage: CIImage, to pixelBuffer: CVPixelBuffer) {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)

        ciContext.render(ciImage, to: pixelBuffer, bounds: bounds, colorSpace: CGColorSpaceCreateDeviceRGB())
    }

    // MARK: - Private: Blend

    private func blendImages(background: CIImage, foreground: CIImage, intensity: Float) -> CIImage {
        let blendFilter = CIFilter.dissolveTransition()
        blendFilter.inputImage = foreground
        blendFilter.targetImage = background
        blendFilter.time = intensity
        return blendFilter.outputImage ?? foreground
    }
}
