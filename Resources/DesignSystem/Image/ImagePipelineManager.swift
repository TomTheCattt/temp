//
//  ImagePipelineManager.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 26/7/26.
//

import Foundation
import Nuke

public enum ImagePipelineManager {

    public static func configure(
        policy: ImageCachePolicy = .default
    ) {

        let dataCache = try? DataCache(name: "ImageCache")

        dataCache?.sizeLimit = policy.diskCacheSize

        let pipeline = ImagePipeline {

            $0.dataLoader = DataLoader()

            $0.imageCache = ImageCache()

            let imageCache = ImageCache()

            imageCache.costLimit = policy.memoryCacheSize
            imageCache.countLimit = 0

            let pipeline = ImagePipeline {
                $0.imageCache = imageCache
            }

            $0.dataCache = dataCache

            $0.isProgressiveDecodingEnabled = true

            $0.isTaskCoalescingEnabled = true

            $0.isRateLimiterEnabled = true
        }

        ImagePipeline.shared = pipeline
    }

    public static func clear() {

        ImagePipeline.shared.cache.removeAll()

        ImagePipeline.shared.configuration.dataCache?.removeAll()
    }
}
