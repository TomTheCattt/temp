//
//  CanvasVideoRenderer.swift
//  Instagram
//
//  Created by Kiro on 15/10/26.
//

import UIKit
import AVFoundation
import SwiftUI
import CoreGraphics

// MARK: - CanvasVideoRenderer

/// High-performance video export engine:
/// - Encodes Story canvas into full HD 1080x1920 (9:16) MP4 video with H.264 at 30 FPS.
/// - Renders live text animations (Typewriter, Reveal with starburst, Bounce).
/// - Zero Memory Leak guarantee: Each frame is strictly wrapped in `@autoreleasepool`.
/// - Reuses buffer memory via `CVPixelBufferPool` for zero-allocation performance.
/// - Completely non-blocking: Runs on user-initiated background queue.
public final class CanvasVideoRenderer: @unchecked Sendable {

    public static let shared = CanvasVideoRenderer()

    private let renderQueue = DispatchQueue(
        label: "com.instagram.story.video.render",
        qos: .userInitiated
    )

    private init() {}

    // MARK: - Public Render Method

    /// Renders a full 1080x1920 MP4 video from gradient, drawings, stickers, and animated texts.
    public func renderVideo(
        gradientColors: [Color],
        drawings: UIImage? = nil,
        stickers: [PIPStickerItem],
        texts: [TextOverlayItem],
        duration: Double = 5.0,
        fps: Int32 = 30,
        progress: (@Sendable (Double) -> Void)? = nil
    ) async throws -> (url: URL, data: Data) {
        return try await withCheckedThrowingContinuation { continuation in
            renderQueue.async {
                do {
                    let result = try self.performRender(
                        gradientColors: gradientColors,
                        drawings: drawings,
                        stickers: stickers,
                        texts: texts,
                        duration: duration,
                        fps: fps,
                        progress: progress
                    )
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Private Video Encoding Pipeline

    private func performRender(
        gradientColors: [Color],
        drawings: UIImage?,
        stickers: [PIPStickerItem],
        texts: [TextOverlayItem],
        duration: Double,
        fps: Int32,
        progress: (@Sendable (Double) -> Void)?
    ) throws -> (url: URL, data: Data) {
        let width = 1080
        let height = 1920
        let totalFrames = Int32(duration * Double(fps))

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("story_export_\(UUID().uuidString).mp4")
        try? FileManager.default.removeItem(at: outputURL)

        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            throw NSError(
                domain: "CanvasVideoRenderer",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to initialize AVAssetWriter"]
            )
        }

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 12_000_000, // 12 Mbps for crystal-clear story video
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoExpectedSourceFrameRateKey: fps
            ]
        ]

        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.expectsMediaDataInRealTime = false

        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferCGImageCompatibilityKey as String: true
        ]

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes
        )

        guard writer.canAdd(input) else {
            throw NSError(
                domain: "CanvasVideoRenderer",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Cannot add video input to AVAssetWriter"]
            )
        }

        writer.add(input)

        guard writer.startWriting() else {
            throw writer.error ?? NSError(
                domain: "CanvasVideoRenderer",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Failed to start writing"]
            )
        }

        writer.startSession(atSourceTime: .zero)

        // Precompute Gradient Background
        let precomputedGradient = createGradientImage(colors: gradientColors, size: CGSize(width: width, height: height))

        // Pre-convert sticker images once to save CPU
        let stickerImages: [(item: PIPStickerItem, image: UIImage)] = stickers.compactMap { item in
            guard let img = UIImage(data: item.imageData) else { return nil }
            return (item, img)
        }

        // Shared Color Space
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // 150 Frames Loop
        for frameIndex in 0..<totalFrames {
            autoreleasepool {
                while !input.isReadyForMoreMediaData {
                    Thread.sleep(forTimeInterval: 0.005)
                }

                let timeInSeconds = Double(frameIndex) / Double(fps)
                let presentationTime = CMTime(value: Int64(frameIndex), timescale: fps)

                // Allocate buffer from pixel buffer pool
                guard let pool = adaptor.pixelBufferPool else {
                    return
                }

                var pixelBufferOut: CVPixelBuffer?
                let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBufferOut)
                guard status == kCVReturnSuccess, let pixelBuffer = pixelBufferOut else {
                    return
                }

                CVPixelBufferLockBaseAddress(pixelBuffer, [])
                defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

                guard let pxData = CVPixelBufferGetBaseAddress(pixelBuffer) else {
                    return
                }

                guard let context = CGContext(
                    data: pxData,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
                ) else {
                    return
                }

                UIGraphicsPushContext(context)
                context.saveGState()

                // CoreGraphics coordinates fix (flip vertical)
                context.translateBy(x: 0, y: CGFloat(height))
                context.scaleBy(x: 1.0, y: -1.0)

                let canvasRect = CGRect(x: 0, y: 0, width: width, height: height)

                // 1. Draw Background Gradient
                precomputedGradient?.draw(in: canvasRect)

                // 2. Draw PencilKit Drawings (if any)
                if let drawings {
                    drawings.draw(in: canvasRect)
                }

                // 3. Draw PIP Stickers
                drawStickers(stickerImages, in: context, canvasSize: CGSize(width: width, height: height))

                // 4. Draw Animated Typography Overlays
                drawAnimatedTexts(texts, at: timeInSeconds, in: context, canvasSize: CGSize(width: width, height: height))

                context.restoreGState()
                UIGraphicsPopContext()

                adaptor.append(pixelBuffer, withPresentationTime: presentationTime)

                progress?(Double(frameIndex) / Double(totalFrames))
            }
        }

        input.markAsFinished()

        let semaphore = DispatchSemaphore(value: 0)
        var finishError: Error?

        writer.finishWriting {
            if let err = writer.error {
                finishError = err
            }
            semaphore.signal()
        }

        semaphore.wait()

        if let finishError {
            throw finishError
        }

        let videoData = try Data(contentsOf: outputURL)
        return (outputURL, videoData)
    }

    // MARK: - Drawing Helpers

    private func createGradientImage(colors: [Color], size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cgContext = ctx.cgContext
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let cgColors = colors.compactMap { UIColor($0).cgColor } as CFArray

            if let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: nil) {
                cgContext.drawLinearGradient(
                    gradient,
                    start: .zero,
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }
        }
    }

    private func drawStickers(
        _ stickers: [(item: PIPStickerItem, image: UIImage)],
        in context: CGContext,
        canvasSize: CGSize
    ) {
        for (sticker, stickerImg) in stickers {
            context.saveGState()

            let baseStickerSize: CGFloat = 280
            let stickerWidth = baseStickerSize * sticker.scale
            let stickerHeight = baseStickerSize * sticker.scale

            let centerX = canvasSize.width / 2 + sticker.offset.width * (canvasSize.width / 360)
            let centerY = canvasSize.height / 2 + sticker.offset.height * (canvasSize.height / 360)

            context.translateBy(x: centerX, y: centerY)
            context.rotate(by: CGFloat(sticker.rotation.radians))

            let drawRect = CGRect(
                x: -stickerWidth / 2,
                y: -stickerHeight / 2,
                width: stickerWidth,
                height: stickerHeight
            )

            let path = pathForShape(sticker.shape, in: drawRect)
            context.addPath(path)
            context.clip()

            stickerImg.draw(in: drawRect)

            context.restoreGState()
        }
    }

    private func drawAnimatedTexts(
        _ texts: [TextOverlayItem],
        at time: Double,
        in context: CGContext,
        canvasSize: CGSize
    ) {
        for textItem in texts {
            context.saveGState()

            var currentText = textItem.text
            var alphaMultiplier: CGFloat = 1.0
            var additionalScale: CGFloat = 1.0
            var yAnimationOffset: CGFloat = 0.0
            var isFlareActive = false

            // Process Animation Type
            switch textItem.animation {
            case .none:
                break

            case .typewriter:
                // Characters appear sequentially over time
                let charsPerSec = 12.0
                let visibleCount = min(currentText.count, max(0, Int(time * charsPerSec)))
                let prefixIndex = currentText.index(currentText.startIndex, offsetBy: visibleCount)
                var animatedString = String(currentText[..<prefixIndex])

                // Blinking cursor
                let isCursorBlink = Int(time * 3.0) % 2 == 0
                if visibleCount < currentText.count && isCursorBlink {
                    animatedString += " |"
                }
                currentText = animatedString

            case .reveal:
                // Smooth fade-in & starburst bloom in the first 1.2s
                let revealDuration = 1.2
                if time < revealDuration {
                    let progress = time / revealDuration
                    alphaMultiplier = CGFloat(progress)
                    additionalScale = CGFloat(0.85 + 0.15 * progress)
                    isFlareActive = (progress > 0.3 && progress < 0.8)
                } else {
                    alphaMultiplier = 1.0
                    additionalScale = 1.0
                }

            case .bounce:
                // Damped spring bounce on Y axis
                let bounceFrequency = 2.0 // 2 bounces per sec
                let decay = exp(-time * 0.4)
                let oscillation = abs(sin(time * .pi * bounceFrequency))
                yAnimationOffset = -CGFloat(oscillation * 26.0 * decay)
                additionalScale = CGFloat(1.0 + 0.04 * cos(time * .pi * 4.0) * decay)
            }

            guard !currentText.isEmpty else {
                context.restoreGState()
                continue
            }

            let centerX = canvasSize.width / 2 + textItem.offset.width * (canvasSize.width / 360)
            let centerY = canvasSize.height / 2 + textItem.offset.height * (canvasSize.height / 360) + yAnimationOffset

            let uiColor = UIColor(textItem.color).withAlphaComponent(alphaMultiplier)
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            var isLight = false
            if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                isLight = (0.299 * red + 0.587 * green + 0.114 * blue) > 0.6
            } else {
                var white: CGFloat = 0
                if uiColor.getWhite(&white, alpha: &alpha) {
                    isLight = white > 0.6
                }
            }

            let badgeColor = (isLight ? UIColor.black.withAlphaComponent(0.65) : UIColor.white.withAlphaComponent(0.85))
                .withAlphaComponent(alphaMultiplier)

            let fontSize = 42 * textItem.scale * additionalScale
            let nsFont = fontForStyle(textItem.fontStyle, effect: textItem.effect, size: fontSize)

            let paragraphStyle = NSMutableParagraphStyle()
            switch textItem.alignment {
            case .leading: paragraphStyle.alignment = .left
            case .center: paragraphStyle.alignment = .center
            case .trailing: paragraphStyle.alignment = .right
            }

            // Glow / Shadow styling based on effects
            let shadow = NSShadow()
            if textItem.effect == .neon {
                let pulse = CGFloat(sin(time * 5.0) * 3.0)
                shadow.shadowColor = uiColor.withAlphaComponent(0.9)
                shadow.shadowOffset = .zero
                shadow.shadowBlurRadius = 10 + pulse
            } else if textItem.effect == .sparkle || isFlareActive {
                shadow.shadowColor = UIColor.white.withAlphaComponent(0.95)
                shadow.shadowOffset = .zero
                shadow.shadowBlurRadius = 12
            } else {
                shadow.shadowColor = UIColor.black.withAlphaComponent(textItem.hasBackground ? 0.35 : 0.7 * alphaMultiplier)
                shadow.shadowOffset = CGSize(width: 0, height: 2)
                shadow.shadowBlurRadius = 4
            }

            let attributes: [NSAttributedString.Key: Any] = [
                .font: nsFont,
                .foregroundColor: uiColor,
                .paragraphStyle: paragraphStyle,
                .shadow: shadow
            ]

            let attributedString = NSAttributedString(string: currentText, attributes: attributes)
            let maxBounds = CGSize(width: canvasSize.width * 0.88, height: canvasSize.height)
            let textBoundingRect = attributedString.boundingRect(
                with: maxBounds,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )

            let textRect = CGRect(
                x: centerX - textBoundingRect.width / 2,
                y: centerY - textBoundingRect.height / 2,
                width: ceil(textBoundingRect.width),
                height: ceil(textBoundingRect.height)
            )

            // Text-Hugging Background Highlight
            if textItem.hasBackground {
                let bgRect = textRect.insetBy(dx: -16, dy: -8)
                let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: 12)
                badgeColor.setFill()
                bgPath.fill()
            }

            attributedString.draw(with: textRect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)

            context.restoreGState()
        }
    }

    private func fontForStyle(_ style: TextFontStyle, effect: TextEffectType, size: CGFloat) -> UIFont {
        if effect == .pixel {
            if let desc = UIFont.monospacedSystemFont(ofSize: size, weight: .bold).fontDescriptor.withDesign(.monospaced) {
                return UIFont(descriptor: desc, size: size)
            }
            return UIFont.monospacedSystemFont(ofSize: size, weight: .bold)
        }

        switch style {
        case .modern:
            return UIFont.systemFont(ofSize: size, weight: .bold)
        case .classic:
            if let desc = UIFont.systemFont(ofSize: size, weight: .regular).fontDescriptor.withDesign(.serif) {
                return UIFont(descriptor: desc, size: size)
            }
            return UIFont.systemFont(ofSize: size, weight: .regular)
        case .signature:
            if let desc = UIFont.systemFont(ofSize: size, weight: .medium).fontDescriptor.withDesign(.rounded)?.withSymbolicTraits(.traitItalic) {
                return UIFont(descriptor: desc, size: size)
            }
            return UIFont.italicSystemFont(ofSize: size)
        case .neon:
            if let desc = UIFont.systemFont(ofSize: size, weight: .semibold).fontDescriptor.withDesign(.rounded) {
                return UIFont(descriptor: desc, size: size)
            }
            return UIFont.systemFont(ofSize: size, weight: .semibold)
        case .typewriter:
            if let desc = UIFont.systemFont(ofSize: size * 0.9, weight: .medium).fontDescriptor.withDesign(.monospaced) {
                return UIFont(descriptor: desc, size: size * 0.9)
            }
            return UIFont.monospacedSystemFont(ofSize: size * 0.9, weight: .medium)
        case .strong:
            if let desc = UIFont.systemFont(ofSize: size * 1.1, weight: .heavy).fontDescriptor.withDesign(.serif) {
                return UIFont(descriptor: desc, size: size * 1.1)
            }
            return UIFont.systemFont(ofSize: size * 1.1, weight: .heavy)
        }
    }

    private func pathForShape(_ shape: StickerShape, in rect: CGRect) -> CGPath {
        switch shape {
        case .roundedRect:
            return UIBezierPath(roundedRect: rect, cornerRadius: 28).cgPath
        case .circle:
            return UIBezierPath(ovalIn: rect).cgPath
        case .square:
            return UIBezierPath(rect: rect).cgPath
        case .heart:
            let side = min(rect.width, rect.height)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addCurve(
                to: CGPoint(x: rect.minX, y: rect.minY + side * 0.3),
                controlPoint1: CGPoint(x: rect.minX + side * 0.1, y: rect.maxY - side * 0.3),
                controlPoint2: CGPoint(x: rect.minX, y: rect.minY + side * 0.6)
            )
            path.addArc(
                withCenter: CGPoint(x: rect.minX + side * 0.25, y: rect.minY + side * 0.25),
                radius: side * 0.25,
                startAngle: .pi,
                endAngle: 0,
                clockwise: true
            )
            path.addArc(
                withCenter: CGPoint(x: rect.maxX - side * 0.25, y: rect.minY + side * 0.25),
                radius: side * 0.25,
                startAngle: .pi,
                endAngle: 0,
                clockwise: true
            )
            path.addCurve(
                to: CGPoint(x: rect.midX, y: rect.maxY),
                controlPoint1: CGPoint(x: rect.maxX, y: rect.minY + side * 0.6),
                controlPoint2: CGPoint(x: rect.maxX - side * 0.1, y: rect.maxY - side * 0.3)
            )
            path.close()
            return path.cgPath
        case .star:
            let path = UIBezierPath()
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let points = 5
            let outerRadius = min(rect.width, rect.height) / 2
            let innerRadius = outerRadius * 0.42
            var angle = -CGFloat.pi / 2
            let step = CGFloat.pi / CGFloat(points)

            for i in 0..<(points * 2) {
                let radius = i % 2 == 0 ? outerRadius : innerRadius
                let point = CGPoint(
                    x: center.x + radius * cos(angle),
                    y: center.y + radius * sin(angle)
                )
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
                angle += step
            }
            path.close()
            return path.cgPath
        }
    }
}
