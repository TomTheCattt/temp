//
//  SplashView.swift
//  Instagram
//
//  Created by Kiro on 30/7/26.
//

import SwiftUI

struct SplashView: View {

    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0.0

    var body: some View {
        if isActive {
            ContentView()
        } else {
            splashContent
                .onAppear {
                    withAnimation(DS.Animation.smooth) {
                        logoScale = 1.0
                        logoOpacity = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(DS.Animation.smooth) {
                            isActive = true
                        }
                    }
                }
        }
    }

    private var splashContent: some View {
        ZStack {
            // Background adapts to light/dark mode
            ColorTokens.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: DS.Spacing.lg) {
                // Instagram camera/gradient icon
                Image(systemName: "camera.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: DS.Size.iconJumbo, height: DS.Size.iconJumbo)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                ColorTokens.brandGradientEnd,
                                ColorTokens.brandGradientMid,
                                ColorTokens.brandGradientStart
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // App name
                Text("Instagram")
                    .font(.system(size: 34, weight: .thin))
                    .foregroundColor(ColorTokens.textPrimary)
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)

            // "from" label at the bottom (like the real Instagram splash)
            VStack {
                Spacer()
                VStack(spacing: DS.Spacing.xxs) {
                    Text("from")
                        .font(DS.Font.caption)
                        .foregroundColor(ColorTokens.textTertiary)
                    Text("Meta")
                        .font(DS.Font.subheadlineBold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    ColorTokens.brandGradientEnd,
                                    ColorTokens.brandGradientMid,
                                    ColorTokens.brandGradientStart
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .padding(.bottom, DS.Spacing.xxxl)
            }
        }
    }
}

#Preview("Light") {
    SplashView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SplashView()
        .preferredColorScheme(.dark)
}
