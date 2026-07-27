//
//  ShimmerModifier.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import SkeletonUI

// MARK: - ShimmerShape

/// Predefined shapes for skeleton placeholders.
enum ShimmerShape {
    case rectangle
    case rounded(CGFloat)
    case capsule
    case circle
}

// MARK: - ShimmerModifier

/// A ViewModifier that wraps SkeletonUI to display a shimmer loading placeholder.
///
/// Usage:
/// ```swift
/// Text("Hello")
///     .shimmer(active: isLoading)
///
/// Image("avatar")
///     .shimmer(active: isLoading, shape: .circle)
///
/// RoundedRectangle(cornerRadius: 8)
///     .frame(height: 200)
///     .shimmer(active: isLoading, shape: .rounded(8))
/// ```
struct ShimmerModifier: ViewModifier {
    let active: Bool
    let shape: ShimmerShape
    let multiline: Int
    let spacing: CGFloat

    func body(content: Content) -> some View {
        if active {
            content
                .skeleton(with: active, shape: skeletonShape)
                .multiline(lines: multiline, scales: nil, spacing: spacing)
        } else {
            content
        }
    }

    private var skeletonShape: RoundedType {
        switch shape {
        case .rectangle:
            return .radius(0, style: .continuous)
        case .rounded(let radius):
            return .radius(radius, style: .continuous)
        case .capsule:
            return .radius(.infinity, style: .continuous)
        case .circle:
            return .radius(.infinity, style: .continuous)
        }
    }
}

// MARK: - View Extension

extension View {

    /// Apply shimmer skeleton loading effect.
    /// - Parameters:
    ///   - active: Whether the skeleton is visible (typically bound to a loading state).
    ///   - shape: The shape of the skeleton placeholder.
    ///   - multiline: Number of skeleton lines (for text-like placeholders).
    ///   - spacing: Spacing between lines when multiline > 1.
    func shimmer(
        active: Bool,
        shape: ShimmerShape = .rounded(8),
        multiline: Int = 1,
        spacing: CGFloat = 8
    ) -> some View {
        modifier(ShimmerModifier(
            active: active,
            shape: shape,
            multiline: multiline,
            spacing: spacing
        ))
    }
}

// MARK: - SkeletonList Helper

/// A convenience view that renders a skeleton list while data is loading.
///
/// Usage:
/// ```swift
/// if isLoading {
///     SkeletonListView(count: 5) {
///         HStack {
///             Circle()
///                 .frame(width: 48, height: 48)
///                 .shimmer(active: true, shape: .circle)
///             VStack(alignment: .leading, spacing: 6) {
///                 Text("Placeholder")
///                     .shimmer(active: true, multiline: 2)
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
        LazyVStack(spacing: 12) {
            ForEach(0..<count, id: \.self) { _ in
                row()
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Skeleton Card Preset

/// A ready-to-use skeleton card for feed-like content.
struct SkeletonCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: avatar + name
            HStack(spacing: 10) {
                Circle()
                    .frame(width: 40, height: 40)
                    .shimmer(active: true, shape: .circle)

                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 120, height: 14)
                        .shimmer(active: true)

                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 80, height: 10)
                        .shimmer(active: true)
                }

                Spacer()
            }

            // Image placeholder
            RoundedRectangle(cornerRadius: 8)
                .frame(height: 200)
                .shimmer(active: true, shape: .rounded(8))

            // Caption lines
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .frame(height: 12)
                    .shimmer(active: true)

                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 200, height: 12)
                    .shimmer(active: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }
}
