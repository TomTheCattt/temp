//
//  CompositeImageRenderer.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import UIKit
import SwiftUI

// MARK: - CompositeImageRenderer

/// High-performance composite renderer that bakes base media, PIP stickers,
/// and typography overlays into a single final image before upload.
@MainActor
public final class CompositeImageRenderer {

    public static let shared = CompositeImageRenderer()

    private init() {}

    /// Renders base image with overlaid PIP stickers and text items into a single UIImage.
    public func render(
        baseImage: UIImage,
        stickers: [PIPStickerItem],
        texts: [TextOverlayItem],
        renderSize: CGSize = CGSize(width: 1080, height: 1080)
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // Fixed 1.0 to preserve exact 1080px dimensions
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)

        return renderer.image { context in
            let cgContext = context.cgContext

            // 1. Draw Base Image
            baseImage.draw(in: CGRect(origin: .zero, size: renderSize))

            // 2. Draw PIP Photo Stickers
            for sticker in stickers {
                guard let stickerImg = UIImage(data: sticker.imageData) else { continue }
                cgContext.saveGState()

                let baseStickerSize: CGFloat = 280
                let stickerWidth = baseStickerSize * sticker.scale
                let stickerHeight = baseStickerSize * sticker.scale

                // Center origin + offset
                let centerX = renderSize.width / 2 + sticker.offset.width * (renderSize.width / 360)
                let centerY = renderSize.height / 2 + sticker.offset.height * (renderSize.height / 360)

                cgContext.translateBy(x: centerX, y: centerY)
                cgContext.rotate(by: CGFloat(sticker.rotation.radians))

                let drawRect = CGRect(
                    x: -stickerWidth / 2,
                    y: -stickerHeight / 2,
                    width: stickerWidth,
                    height: stickerHeight
                )

                // Apply Shape Clipping Path
                let path = pathForShape(sticker.shape, in: drawRect)
                cgContext.addPath(path)
                cgContext.clip()

                stickerImg.draw(in: drawRect)

                cgContext.restoreGState()
            }

            // 3. Draw Typography Overlays
            for textItem in texts {
                cgContext.saveGState()

                let centerX = renderSize.width / 2 + textItem.offset.width * (renderSize.width / 360)
                let centerY = renderSize.height / 2 + textItem.offset.height * (renderSize.height / 360)

                let uiColor = UIColor(textItem.color)
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

                let badgeColor = isLight ? UIColor.black.withAlphaComponent(0.65) : UIColor.white.withAlphaComponent(0.85)

                let fontSize = 42 * textItem.scale
                let nsFont: UIFont
                switch textItem.fontStyle {
                case .modern:
                    nsFont = UIFont.systemFont(ofSize: fontSize, weight: .bold)
                case .classic:
                    if let descriptor = UIFont.systemFont(ofSize: fontSize, weight: .regular).fontDescriptor.withDesign(.serif) {
                        nsFont = UIFont(descriptor: descriptor, size: fontSize)
                    } else {
                        nsFont = UIFont.systemFont(ofSize: fontSize, weight: .regular)
                    }
                case .signature:
                    if let descriptor = UIFont.systemFont(ofSize: fontSize, weight: .medium).fontDescriptor.withDesign(.rounded)?.withSymbolicTraits(.traitItalic) {
                        nsFont = UIFont(descriptor: descriptor, size: fontSize)
                    } else {
                        nsFont = UIFont.italicSystemFont(ofSize: fontSize)
                    }
                case .neon:
                    if let descriptor = UIFont.systemFont(ofSize: fontSize, weight: .semibold).fontDescriptor.withDesign(.rounded) {
                        nsFont = UIFont(descriptor: descriptor, size: fontSize)
                    } else {
                        nsFont = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
                    }
                case .typewriter:
                    if let descriptor = UIFont.systemFont(ofSize: fontSize * 0.9, weight: .medium).fontDescriptor.withDesign(.monospaced) {
                        nsFont = UIFont(descriptor: descriptor, size: fontSize * 0.9)
                    } else {
                        nsFont = UIFont.monospacedSystemFont(ofSize: fontSize * 0.9, weight: .medium)
                    }
                case .strong:
                    if let descriptor = UIFont.systemFont(ofSize: fontSize * 1.1, weight: .heavy).fontDescriptor.withDesign(.serif) {
                        nsFont = UIFont(descriptor: descriptor, size: fontSize * 1.1)
                    } else {
                        nsFont = UIFont.systemFont(ofSize: fontSize * 1.1, weight: .heavy)
                    }
                }

                let paragraphStyle = NSMutableParagraphStyle()
                switch textItem.alignment {
                case .leading: paragraphStyle.alignment = .left
                case .center: paragraphStyle.alignment = .center
                case .trailing: paragraphStyle.alignment = .right
                }

                let shadow = NSShadow()
                shadow.shadowColor = UIColor.black.withAlphaComponent(textItem.hasBackground ? 0.35 : 0.7)
                shadow.shadowOffset = CGSize(width: 0, height: 2)
                shadow.shadowBlurRadius = 4

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: nsFont,
                    .foregroundColor: uiColor,
                    .paragraphStyle: paragraphStyle,
                    .shadow: shadow
                ]

                let attributedString = NSAttributedString(string: textItem.text, attributes: attributes)
                let maxBounds = CGSize(width: renderSize.width * 0.88, height: renderSize.height)
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

                if textItem.hasBackground {
                    let bgRect = textRect.insetBy(dx: -16, dy: -8)
                    let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: 12)
                    badgeColor.setFill()
                    bgPath.fill()
                }

                attributedString.draw(with: textRect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)

                cgContext.restoreGState()
            }
        }
    }

    // MARK: - Shape Path Helper

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
