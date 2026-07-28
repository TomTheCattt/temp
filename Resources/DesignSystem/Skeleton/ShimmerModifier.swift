//
//  ShimmerModifier.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI

// MARK: - ShimmerModifier

/// A custom shimmer/skeleton loading effect implemented in pure SwiftUI.
/// No external dependency — uses gradient animation for the shimmer effect.
///
/// Usage:
/// ```swift
/// RoundedRectangle(cornerRadius: 8)
///     .frame(height: 200)
///     .shimmer(active: isLoading)
///
/// Circle()
///     .frame(width: 48, height: 48)
///     .shimmer(active: isLoading)
/// ```
struct ShimmerModifier: ViewModifier {

    let active: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if active {
            content
                .redacted(reason: .placeholder)
                .overlay(shimmerOverlay)
                .mask(content)
        } else {
            content
        }
    }

    private var shimmerOverlay: some View {
        GeometryReader { geometry in
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: Color.white.opacity(0.4), location: 0.3),
                    .init(color: Color.white.opacity(0.6), location: 0.5),
                    .init(color: Color.white.opacity(0.4), location: 0.7),
                    .init(color: .clear, location: 1.0)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 2)
            .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1.0
                }
            }
        }
        .clipped()
    }
}

// MARK: - View Extension

extension View {

    /// Apply shimmer skeleton loading effect.
    /// - Parameter active: Whether the skeleton shimmer is visible.
    func shimmer(active: Bool) -> some View {
        modifier(ShimmerModifier(active: active))
    }
}

// MARK: - SkeletonListView

/// A convenience view that renders a skeleton list while data is loading.
///
/// Usage:
/// ```swift
/// if isLoading {
///     SkeletonListView(count: 5) {
///         HStack {
///             Circle()
///                 .fill(Color.gray.opacity(0.2))
///                 .frame(width: 48, height: 48)
///             VStack(alignment: .leading, spacing: 6) {
///                 RoundedRectangle(cornerRadius: 4)
///                     .fill(Color.gray.opacity(0.2))
///                     .frame(height: 14)
///                 RoundedRectangle(cornerRadius: 4)
///                     .fill(Color.gray.opacity(0.2))
///                     .frame(width: 100, height: 10)
///             }
///         }
///     }
/// }
/// ```
struct SkeletonListView<Row: View>: View {
    let count: Int
    let row: () -> Row

    init(count: Int = 5, @ViewBuilder row: @escaping () -> Row) {
        self.count = count
        self.row = row
    }

    var body: some View {
        LazyVStack(spacing: DS.Spacing.sm) {
            ForEach(0..<count, id: \.self) { _ in
                row()
                    .shimmer(active: true)
            }
        }
        .padding(.horizontal, DS.Padding.horizontal)
    }
}

// MARK: - SkeletonCardView

/// A ready-to-use skeleton card for feed-like content.
struct SkeletonCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            // Header: avatar + name
            HStack(spacing: DS.Spacing.sm) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: DS.Spacing.xxxl, height: DS.Spacing.xxxl)

                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    RoundedRectangle(cornerRadius: DS.Radius.small)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: DS.Spacing.formGap)

                    RoundedRectangle(cornerRadius: DS.Radius.small)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: DS.Padding.inputBar)
                }

                Spacer()
            }

            // Image placeholder
            RoundedRectangle(cornerRadius: DS.Radius.medium)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 200)

            // Caption lines
            VStack(alignment: .leading, spacing: DS.Spacing.iconGap) {
                RoundedRectangle(cornerRadius: DS.Radius.small)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: DS.Spacing.sm)

                RoundedRectangle(cornerRadius: DS.Radius.small)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200, height: DS.Spacing.sm)
            }
        }
        .padding(DS.Padding.horizontal)
        .shimmer(active: true)
    }
}
