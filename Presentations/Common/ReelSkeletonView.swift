//
//  ReelSkeletonView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI

// MARK: - ReelSkeletonView

/// Full-screen skeleton loading placeholder that mimics ReelItemView layout.
struct ReelSkeletonView: View {

    var body: some View {
        ZStack {
            // Background
            Color.black

            // Shimmer overlay
            ShimmerView()
                .opacity(DS.Opacity.low)

            // Content overlay mimicking reel layout
            VStack {
                Spacer()
                HStack(alignment: .bottom, spacing: DS.Spacing.sm) {
                    // Left: user info skeleton
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        HStack(spacing: DS.Spacing.xs) {
                            Circle()
                                .fill(Color.white.opacity(DS.Opacity.low))
                                .frame(width: DS.Size.avatarCompact, height: DS.Size.avatarCompact)
                            SkeletonShape(width: 100, height: 12, cornerRadius: DS.Radius.small)
                                .opacity(0.3)
                        }
                        SkeletonShape(width: 200, height: 10, cornerRadius: DS.Radius.small)
                            .opacity(0.3)
                        SkeletonShape(width: 150, height: 10, cornerRadius: DS.Radius.small)
                            .opacity(0.3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Right: action buttons skeleton
                    VStack(spacing: DS.Spacing.lg) {
                        ForEach(0..<4, id: \.self) { _ in
                            VStack(spacing: DS.Spacing.xxs) {
                                Circle()
                                    .fill(Color.white.opacity(DS.Opacity.low))
                                    .frame(width: 28, height: 28)
                                SkeletonShape(width: 30, height: 8, cornerRadius: DS.Radius.small)
                                    .opacity(0.3)
                            }
                        }
                    }
                }
                .padding(.horizontal, DS.Padding.content)
                .padding(.bottom, DS.Padding.bottomSafe + 49)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
