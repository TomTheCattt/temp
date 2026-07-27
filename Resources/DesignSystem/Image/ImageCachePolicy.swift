//
//  ImageCachePolicy.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 26/7/26.
//

import Foundation
import Nuke

public struct ImageCachePolicy: Sendable {

    public let memoryCacheSize: Int
    public let diskCacheSize: Int
    public let diskCacheExpiration: TimeInterval

    public init(
        memoryCacheSize: Int = 100 * 1024 * 1024,
        diskCacheSize: Int = 500 * 1024 * 1024,
        diskCacheExpiration: TimeInterval = 7 * 24 * 60 * 60
    ) {
        self.memoryCacheSize = memoryCacheSize
        self.diskCacheSize = diskCacheSize
        self.diskCacheExpiration = diskCacheExpiration
    }

    public static let `default` = ImageCachePolicy()

    public static let lightweight = ImageCachePolicy(
        memoryCacheSize: 50 * 1024 * 1024,
        diskCacheSize: 100 * 1024 * 1024,
        diskCacheExpiration: 3 * 24 * 60 * 60
    )
}
