//
//  SplashView.swift
//  Instagram
//
//  Created by Kiro on 30/7/26.
//

import SwiftUI

struct SplashView: View {
    
    private enum Constants {
        static let splashIconSize: CGFloat = 88
        static let splashFooterWidth: CGFloat = 77
        static let splashFooterHeight: CGFloat = 39
        static let spacing: CGFloat = 283
        static let paddingBottomConstant: CGFloat = 51
    }

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

            VStack(spacing: Constants.spacing) {
                
                Spacer()
                
                // Instagram camera/gradient icon
                Image(.splashIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.splashIconSize, height: Constants.splashIconSize)

                // App name
                Image(.splashFooter)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.splashFooterWidth, height: Constants.splashFooterHeight)
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
            .ignoresSafeArea()
            .padding(.bottom, Constants.paddingBottomConstant)
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
