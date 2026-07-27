//
//  ImagePrefetcher.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 26/7/26.
//

import Foundation
import Nuke

public final class ImagePrefetchService {

    public static let shared = ImagePrefetchService()

    private var prefetcher: ImagePrefetcher?

    private init() {}

    public func startPrefetching(
        urls: [URL]
    ) {

        stop()

        prefetcher = ImagePrefetcher(
            pipeline: .shared,
            destination: .diskCache,
            maxConcurrentRequestCount: 4
        )

        prefetcher?.startPrefetching(with: urls)
    }

    public func stop() {

        prefetcher?.stopPrefetching()

        prefetcher = nil
    }
}
