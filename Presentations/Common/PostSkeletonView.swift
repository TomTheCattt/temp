//
//  PostSkeletonView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI

// MARK: - PostSkeletonView

/// Skeleton loading placeholder that mimics PostCardView layout.
struct PostSkeletonView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header skeleton
            HStack(spacing: DS.Spacing.sm) {
                Circle()
                    .fill(ColorTokens.backgroundSubtler)
                    .frame(width: DS.Size.avatarCompact, height: DS.Size.avatarCompact)

                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    SkeletonShape(width: 100, height: 12)
                    SkeletonShape(width: 60, height: 10)
                }

                Spacer()
            }
            .padding(.horizontal, DS.Padding.content)
            .padding(.vertical, DS.Spacing.xs)

            // Image skeleton
            Rectangle()
                .fill(ColorTokens.backgroundSubtler)
                .aspectRatio(DS.Layout.postSquareAspectRatio, contentMode: .fill)
                .overlay { ShimmerView() }
                .clipped()

            // Actions skeleton
            HStack(spacing: DS.Spacing.md) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(ColorTokens.backgroundSubtler)
                        .frame(width: 24, height: 24)
                }
                Spacer()
                Circle()
                    .fill(ColorTokens.backgroundSubtler)
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, DS.Padding.content)
            .padding(.vertical, DS.Padding.inputBar)

            // Caption skeleton
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                SkeletonShape(width: 80, height: 12)
                SkeletonShape(height: 12)
                SkeletonShape(width: 200, height: 12)
            }
            .padding(.horizontal, DS.Padding.content)
            .padding(.bottom, DS.Spacing.sm)
        }
    }
}

// MARK: - FeedSkeletonView

/// Multiple post skeletons for the initial feed loading state.
struct FeedSkeletonView: View {

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { _ in
                PostSkeletonView()
                Divider()
            }
        }
    }
}
