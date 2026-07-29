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
/// - Generate all thumbnails sequentially (150x150 is fast, avoids Sendable issues with CIImage)
/// - Cache results in memory so re-opening the picker is instant
///
/// Thread-safe via NSLock. Uses @unchecked Sendable instead of actor to avoid
/// crossing-boundary warnings with non-Sendable types (CIImage, existential ImageFilter).
final class FilterThumbnailGenerator: @unchecked Sendable {

    static let shared = FilterThumbnailGenerator()

    // MARK: - Cache

    private let lock = NSLock()
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
        let cached: [FilterThumbnail]? = lock.withLock { cache[cacheKey] }
        if let cached {
            return cached
        }

        // Downscale source image ONCE to thumbnail size
        guard let sourceCIImage = prepareThumbnailSource(from: sourceImage) else {
            return []
        }

        let engine = FilterEngine.shared
        let size = thumbnailSize

        // Process sequentially — 150x150 renders are fast, no need for TaskGroup
        var thumbnails: [FilterThumbnail] = []
        thumbnails.reserveCapacity(filters.count)

        for filter in filters {
            let filtered = engine.apply(filter: filter, to: sourceCIImage)
            if let uiImage = engine.renderThumbnail(filtered, size: size) {
                thumbnails.append(FilterThumbnail(
                    id: filter.id,
                    displayName: filter.displayName,
                    image: uiImage
                ))
            }
        }

        // Cache
        lock.withLock { cache[cacheKey] = thumbnails }
        return thumbnails
    }

    /// Invalidate cached thumbnails (e.g., when switching to a different photo).
    func invalidateCache(key: String? = nil) {
        lock.withLock {
            if let key {
                cache.removeValue(forKey: key)
            } else {
                cache.removeAll()
            }
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
