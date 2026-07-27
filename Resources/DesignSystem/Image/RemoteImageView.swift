//
//  RemoteImageView.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 26/7/26.
//

import SwiftUI
import NukeUI

public struct RemoteImageView<
    Placeholder: View,
    Failure: View
>: View {

    private let url: URL?

    private let placeholder: Placeholder

    private let failure: Failure

    public init(
        url: URL?,
        @ViewBuilder placeholder: () -> Placeholder,
        @ViewBuilder failure: () -> Failure
    ) {

        self.url = url
        self.placeholder = placeholder()
        self.failure = failure()
    }

    public var body: some View {

        if let url {

            LazyImage(url: url) { state in

                if let image = state.image {

                    image
                        .resizable()

                } else if state.error != nil {

                    failure

                } else {

                    placeholder
                }
            }

        } else {

            failure
        }
    }
}
