//
//  ImageProcessors.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 26/7/26.
//

import Foundation
import UIKit
import Nuke

enum AppImageProcessors {

    static func avatar(size: CGFloat = 200) -> any ImageProcessing {
        ImageProcessors.Resize(
            size: CGSize(width: size, height: size),
            unit: .points,
            contentMode: .aspectFill
        )
    }

    static func thumbnail(
        width: CGFloat = 400,
        height: CGFloat = 400
    ) -> any ImageProcessing {
        ImageProcessors.Resize(
            size: CGSize(width: width, height: height),
            unit: .points,
            contentMode: .aspectFill
        )
    }

    static func banner(
        width: CGFloat = 1200,
        height: CGFloat = 600
    ) -> any ImageProcessing {
        ImageProcessors.Resize(
            size: CGSize(width: width, height: height),
            unit: .points,
            contentMode: .aspectFill
        )
    }

    static func resize(
        width: CGFloat,
        height: CGFloat,
        contentMode: ImageProcessingOptions.ContentMode = .aspectFill
    ) -> any ImageProcessing {

        ImageProcessors.Resize(
            size: CGSize(width: width, height: height),
            unit: .points,
            contentMode: contentMode
        )
    }
}
