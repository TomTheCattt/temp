//
//  VideoThumbnailGenerator.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import AVFoundation
import UIKit

// MARK: - VideoThumbnailGenerator

/// Generates thumbnail images from video URLs.
/// - Uses in-memory cache to avoid re-generating for the same URL
/// - Async-safe, runs image generation on background thread
/// - Falls back gracefully if generation fails
final class VideoThumbnailGenerator: @unchecked Sendable {

    static let shared = VideoThumbnailGenerator()

    private let cache = NSCache<NSString, UIImage>()
    private let queue = DispatchQueue(label: "com.instagram.thumbnail-generator", qos: .utility)

    private init() {
        cache.countLimit = 50 // Max 50 thumbnails cached
    }

    // MARK: - Public API

    /// Generate a thumbnail for a video URL.
    /// Returns cached result if available, otherwise generates from the video's first frame.
    /// - Parameters:
    ///   - url: The video URL (remote or local)
    ///   - time: The time in the video to capture (default: 0.1s to skip potential black frames)
    /// - Returns: UIImage thumbnail or nil if generation fails
    func thumbnail(for url: URL, at time: TimeInterval = 0.1) async -> UIImage? {
        let cacheKey = url.absoluteString as NSString

        // Check cache first
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        // Generate on background queue
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self else {
                    continuation.resume(returning: nil)
                    return
                }

                let asset = AVAsset(url: url)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = CGSize(width: 540, height: 960) // Half resolution for performance
                generator.requestedTimeToleranceBefore = .zero
                generator.requestedTimeToleranceAfter = CMTime(seconds: 1, preferredTimescale: 600)

                let cmTime = CMTime(seconds: time, preferredTimescale: 600)

                do {
                    let cgImage = try generator.copyCGImage(at: cmTime, actualTime: nil)
                    let image = UIImage(cgImage: cgImage)
                    self.cache.setObject(image, forKey: cacheKey)
                    continuation.resume(returning: image)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    /// Clear the thumbnail cache (e.g. on memory warning).
    func clearCache() {
        cache.removeAllObjects()
    }
}
