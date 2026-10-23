//
//  ImageDownsampler.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import UIKit
import ImageIO

// MARK: - ImageDownsampler

/// Memory-efficient image downsampling utility using low-level Image I/O.
/// Prevents large images (12MP-48MP, 60MB-180MB uncompressed bitmap in RAM)
/// from exhausting device memory and causing OOM crashes.
nonisolated public final class ImageDownsampler: @unchecked Sendable {

    nonisolated public static let shared = ImageDownsampler()

    /// In-memory LRU cache for downsampled images to achieve smooth 60fps scrolling.
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        cache.countLimit = 60
    }

    // MARK: - Public API

    /// Downsample raw image Data to a memory-efficient UIImage with the given max dimension.
    /// Preserves EXIF orientation and downsamples directly at decode time.
    public func downsample(data: Data, maxDimension: CGFloat = 1080) -> UIImage? {
        let cacheKey = NSString(string: "\(data.hashValue)_\(Int(maxDimension))")
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return UIImage(data: data)
        }

        let downsampled = createThumbnail(from: imageSource, maxDimension: maxDimension)
        if let downsampled {
            cache.setObject(downsampled, forKey: cacheKey, cost: Int(downsampled.size.width * downsampled.size.height * 4))
        }
        return downsampled ?? UIImage(data: data)
    }

    /// Downsample image file URL to a memory-efficient UIImage with the given max dimension.
    public func downsample(url: URL, maxDimension: CGFloat = 1080) -> UIImage? {
        let cacheKey = NSString(string: "\(url.path)_\(Int(maxDimension))")
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) else {
            return UIImage(contentsOfFile: url.path)
        }

        let downsampled = createThumbnail(from: imageSource, maxDimension: maxDimension)
        if let downsampled {
            cache.setObject(downsampled, forKey: cacheKey, cost: Int(downsampled.size.width * downsampled.size.height * 4))
        }
        return downsampled
    }

    /// Downsamples data and returns optimized JPEG Data for transmission/storage.
    public func downsampleToData(data: Data, maxDimension: CGFloat = 1080, compressionQuality: CGFloat = 0.85) -> Data? {
        guard let image = downsample(data: data, maxDimension: maxDimension) else {
            return data
        }
        return image.jpegData(compressionQuality: compressionQuality)
    }

    /// Clear the in-memory cache when system warns of low memory.
    public func clearCache() {
        cache.removeAllObjects()
    }

    // MARK: - Private Helper

    private func createThumbnail(from imageSource: CGImageSource, maxDimension: CGFloat) -> UIImage? {
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]

        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: downsampledImage)
    }
}
