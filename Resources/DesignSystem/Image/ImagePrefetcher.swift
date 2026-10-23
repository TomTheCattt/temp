//
//  ImagePrefetcher.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 26/7/26.
//

import Foundation
import Nuke

final class ImagePrefetchService {

    static let shared = ImagePrefetchService()

    private var prefetcher: ImagePrefetcher?

    private init() {}

    func startPrefetching(
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

    func stop() {

        prefetcher?.stopPrefetching()

        prefetcher = nil
    }
}
