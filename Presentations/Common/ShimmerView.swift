//
//  ShimmerView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI

// MARK: - ShimmerView

/// Animated shimmer effect for skeleton loading states.
struct ShimmerView: View {

    @State private var phase: CGFloat = -1.0

    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                stops: [
                    .init(color: .clear, location: max(0, phase - 0.3)),
                    .init(color: Color.white.opacity(DS.Opacity.low), location: phase),
                    .init(color: .clear, location: min(1, phase + 0.3))
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 2.0
                }
            }
        }
        .clipped()
    }
}

// MARK: - SkeletonShape

/// Configurable skeleton placeholder shape.
struct SkeletonShape: View {

    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    init(width: CGFloat? = nil, height: CGFloat = 14, cornerRadius: CGFloat = DS.Radius.small) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(ColorTokens.backgroundSubtler)
            .frame(width: width, height: height)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.clear)
                    .overlay { ShimmerView() }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
    }
}
