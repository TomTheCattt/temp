//
//  ImagePipelineManager.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 26/7/26.
//

import Foundation
import Nuke

enum ImagePipelineManager {

    /// Shared prefetcher instance configured to use the shared ImagePipeline.
    static let prefetcher = ImagePrefetcher(pipeline: ImagePipeline.shared)

    static func configure(
        policy: ImageCachePolicy = .default
    ) {
        let dataCache = try? DataCache(name: "ImageCache")
        dataCache?.sizeLimit = policy.diskCacheSize

        let memoryCache = ImageCache()
        memoryCache.costLimit = policy.memoryCacheSize
        memoryCache.countLimit = 0

        let pipeline = ImagePipeline {
            $0.dataLoader = DataLoader()
            $0.imageCache = memoryCache
            $0.dataCache = dataCache
            $0.isProgressiveDecodingEnabled = true
            $0.isTaskCoalescingEnabled = true
            $0.isRateLimiterEnabled = true
        }

        ImagePipeline.shared = pipeline
    }

    static func clear() {
        ImagePipeline.shared.cache.removeAll()
        ImagePipeline.shared.configuration.dataCache?.removeAll()
    }
}
