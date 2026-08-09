//
//  CustomNavBarView.swift
//  Instagram
//
//  Created by Kiro on 9/8/26.
//

import SwiftUI

// MARK: - CustomNavBarView

/// Custom Navigation Bar container replacing system liquid glass bars.
struct CustomNavBarView<Leading: View, Center: View, Trailing: View>: View {

    let leading: Leading
    let center: Center
    let trailing: Trailing
    let showDivider: Bool
    let isScrolled: Bool
    let useBlur: Bool

    init(
        showDivider: Bool = true,
        isScrolled: Bool = false,
        useBlur: Bool = false,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder center: () -> Center = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.showDivider = showDivider
        self.isScrolled = isScrolled
        self.useBlur = useBlur
        self.leading = leading()
        self.center = center()
        self.trailing = trailing()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: DS.Spacing.xs) {
                leading
                    .frame(minWidth: DS.Size.buttonDefaultHeight, alignment: .leading)

                Spacer(minLength: 0)

                center
                    .frame(maxWidth: .infinity, alignment: .center)

                Spacer(minLength: 0)

                trailing
                    .frame(minWidth: DS.Size.buttonDefaultHeight, alignment: .trailing)
            }
            .padding(.horizontal, DS.Padding.horizontal)
            .frame(height: DS.Size.buttonDefaultHeight)

            if showDivider && isScrolled {
                Divider()
                    .opacity(DS.Opacity.divider)
            }
        }
        .background {
            if isScrolled {
                if useBlur {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(Constants.gradientStopFull),
                                    Color.white.opacity(Constants.gradientStopHigh),
                                    Color.white.opacity(Constants.gradientStopMid),
                                    Color.white.opacity(Constants.gradientStopClear)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    Color(.systemBackground)
                }
            } else {
                Color.clear
            }
        }
        .animation(DS.Animation.standard, value: isScrolled)
    }
}

// MARK: - Constants

private enum Constants {
    static let gradientStopFull: Double = 0.95
    static let gradientStopHigh: Double = 0.70
    static let gradientStopMid: Double = 0.30
    static let gradientStopClear: Double = 0.00
}
