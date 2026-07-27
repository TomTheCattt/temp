//
//  ImageLoader.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 26/7/26.
//

import Foundation
import UIKit
import Nuke

public protocol ImageLoading {

    func loadImage(
        from url: URL
    ) async throws -> UIImage

    func cachedImage(
        for url: URL
    ) -> UIImage?
}

public final class ImageLoader: ImageLoading {

    public static let shared = ImageLoader()

    private init() {}

    public func loadImage(
        from url: URL
    ) async throws -> UIImage {

        let response = try await ImagePipeline.shared.image(for: url)

        return response
    }

    public func cachedImage(
        for url: URL
    ) -> UIImage? {

        ImagePipeline.shared.cache[url]?.image
    }
}

extension ImageLoader {

    public func preload(
        url: URL
    ) {

        let request = ImageRequest(url: url)

        ImagePipeline.shared.loadImage(
            with: request
        ) { _ in }
    }
}

extension ImageLoader {

    public func removeCache(
        for url: URL
    ) {

        ImagePipeline.shared.cache.removeCachedImage(
            for: ImageRequest(url: url)
        )

        ImagePipeline.shared.configuration
            .dataCache?
            .removeData(for: url.absoluteString)
    }
}

extension ImageLoader {

    public func preload(
        urls: [URL]
    ) async {

        await withTaskGroup(of: Void.self) { group in

            for url in urls {

                group.addTask {

                    _ = try? await self.loadImage(from: url)

                }

            }

        }
    }
}
