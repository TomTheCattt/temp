//
//  CarouselPageIndicator.swift
//  Instagram
//
//  Created by Kiro on 17/10/26.
//

import SwiftUI

// MARK: - CarouselPageIndicator

/// Custom page indicator dots matching Instagram iOS native style.
/// - Active dot: 6pt diameter, accentPrimary (Instagram blue).
/// - Inactive dots: 4.5pt diameter, subtle secondary tint.
/// - Smooth spring animation when switching pages.
/// - Interactive tap-to-navigate support.
struct CarouselPageIndicator: View {

    let pageCount: Int
    @Binding var currentIndex: Int

    var body: some View {
        if pageCount > 1 {
            HStack(spacing: DS.Spacing.xxs) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Circle()
                        .fill(currentIndex == index ? ColorTokens.accentPrimary : Color.secondary.opacity(0.35))
                        .frame(
                            width: currentIndex == index ? 6 : 4.5,
                            height: currentIndex == index ? 6 : 4.5
                        )
                        .contentShape(Rectangle().size(width: 14, height: 14))
                        .onTapGesture {
                            withAnimation(DS.Animation.smooth) {
                                currentIndex = index
                            }
                        }
                }
            }
            .animation(DS.Animation.smooth, value: currentIndex)
        }
    }
}
