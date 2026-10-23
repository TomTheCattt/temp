//
//  ImageCachePolicy.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 26/7/26.
//

import Foundation
import Nuke

struct ImageCachePolicy: Sendable {

    let memoryCacheSize: Int
    let diskCacheSize: Int
    let diskCacheExpiration: TimeInterval

    init(
        memoryCacheSize: Int = 100 * 1024 * 1024,
        diskCacheSize: Int = 500 * 1024 * 1024,
        diskCacheExpiration: TimeInterval = 7 * 24 * 60 * 60
    ) {
        self.memoryCacheSize = memoryCacheSize
        self.diskCacheSize = diskCacheSize
        self.diskCacheExpiration = diskCacheExpiration
    }

    static let `default` = ImageCachePolicy()

    static let lightweight = ImageCachePolicy(
        memoryCacheSize: 50 * 1024 * 1024,
        diskCacheSize: 100 * 1024 * 1024,
        diskCacheExpiration: 3 * 24 * 60 * 60
    )
}
