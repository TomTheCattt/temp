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

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 42 * textItem.scale, weight: .bold),
                    .foregroundColor: UIColor(textItem.color)
                ]

                let attributedString = NSAttributedString(string: textItem.text, attributes: attributes)
                let textSize = attributedString.size()

                let textRect = CGRect(
                    x: centerX - textSize.width / 2,
                    y: centerY - textSize.height / 2,
                    width: textSize.width,
                    height: textSize.height
                )

                if textItem.hasBackground {
                    let bgRect = textRect.insetBy(dx: -16, dy: -8)
                    let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: 12)
                    UIColor.black.withAlphaComponent(0.65).setFill()
                    bgPath.fill()
                }

                attributedString.draw(in: textRect)

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
