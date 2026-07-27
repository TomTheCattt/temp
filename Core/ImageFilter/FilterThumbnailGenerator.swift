//
//  FilterThumbnailGenerator.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import CoreImage
import UIKit

// MARK: - FilterThumbnail

struct FilterThumbnail: Identifiable, Sendable {
    let id: String
    let displayName: String
    let image: UIImage
}

// MARK: - FilterThumbnailGenerator

/// Generates preview thumbnails for all filters in batch.
/// Renders at low resolution (150x150) for fast scrolling in the filter picker.
///
/// Performance strategy:
/// - Downscale source image ONCE to thumbnail size before applying filters
/// - Generate all thumbnails on a background task concurrently
/// - Cache results in memory so re-opening the picker is instant
actor FilterThumbnailGenerator {

    static let shared = FilterThumbnailGenerator()

    // MARK: - Cache

    private var cache: [String: [FilterThumbnail]] = [:]
    private let thumbnailSize = CGSize(width: 150, height: 150)

    // MARK: - Generate

    /// Generate thumbnails for all registered filters given a source image.
    /// Returns cached results if the same image key was used before.
    func generateThumbnails(
        for sourceImage: UIImage,
        cacheKey: String = "default",
        filters: [ImageFilter] = FilterRegistry.allFilters
    ) async -> [FilterThumbnail] {
        // Return cached if available
        if let cached = cache[cacheKey] {
            return cached
        }

        // Downscale source image ONCE to thumbnail size
        guard let sourceCIImage = prepareThumbnailSource(from: sourceImage) else {
            return []
        }

        let engine = FilterEngine.shared

        // Generate thumbnails concurrently
        let thumbnails = await withTaskGroup(of: (Int, FilterThumbnail?).self) { group in
            for (index, filter) in filters.enumerated() {
                group.addTask {
                    let filtered = engine.apply(filter: filter, to: sourceCIImage)
                    guard let uiImage = engine.renderThumbnail(filtered, size: self.thumbnailSize) else {
                        return (index, nil)
                    }
                    let thumbnail = FilterThumbnail(
                        id: filter.id,
                        displayName: filter.displayName,
                        image: uiImage
                    )
                    return (index, thumbnail)
                }
            }

            // Collect results maintaining order
            var results = [(Int, FilterThumbnail?)]()
            for await result in group {
                results.append(result)
            }
            return results
                .sorted { $0.0 < $1.0 }
                .compactMap { $0.1 }
        }

        // Cache
        cache[cacheKey] = thumbnails
        return thumbnails
    }

    /// Invalidate cached thumbnails (e.g., when switching to a different photo).
    func invalidateCache(key: String? = nil) {
        if let key {
            cache.removeValue(forKey: key)
        } else {
            cache.removeAll()
        }
    }

    // MARK: - Private

    /// Downscale source image to thumbnail size as CIImage.
    private func prepareThumbnailSource(from image: UIImage) -> CIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let scale = min(
            thumbnailSize.width / ciImage.extent.width,
            thumbnailSize.height / ciImage.extent.height
        )

        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Center crop to exact thumbnail size
        let xOffset = (scaled.extent.width - thumbnailSize.width) / 2
        let yOffset = (scaled.extent.height - thumbnailSize.height) / 2
        let cropRect = CGRect(
            x: scaled.extent.origin.x + max(0, xOffset),
            y: scaled.extent.origin.y + max(0, yOffset),
            width: min(thumbnailSize.width, scaled.extent.width),
            height: min(thumbnailSize.height, scaled.extent.height)
        )

        return scaled.cropped(to: cropRect)
    }
}
