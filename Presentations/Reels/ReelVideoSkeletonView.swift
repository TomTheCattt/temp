//
//  ReelVideoSkeletonView.swift
//  Instagram
//
//  Created by Kiro on 13/10/26.
//

import SwiftUI

// MARK: - ReelVideoSkeletonView

/// Dark skeleton loading placeholder for Reels videos while buffering/loading.
/// - Pure black background
/// - Subtle dark shimmer overlay active only when `isActive == true` to save GPU/CPU cycles
struct ReelVideoSkeletonView: View {

    let isActive: Bool

    var body: some View {
        ZStack {
            Color.black

            if isActive {
                ShimmerView()
                    .opacity(DS.Opacity.placeholder)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}
