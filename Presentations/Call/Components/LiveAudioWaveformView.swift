//
//  LiveAudioWaveformView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import Combine

// MARK: - LiveAudioWaveformStyle

enum LiveAudioWaveformStyle {
    /// Equalizer-style vertical dancing bars (5 bars)
    case bars
    /// Concentric expanding aura rings around caller avatar
    case rings(baseRadius: CGFloat = DS.Size.avatarCall)
}

// MARK: - LiveAudioWaveformView

/// High-performance SwiftUI component visualizing real-time RMS audio levels (0.0 ... 1.0).
/// Supports ProMotion 60/120 FPS smooth spring animations with zero layout thrashing.
struct LiveAudioWaveformView: View {

    // MARK: - Properties

    private let style: LiveAudioWaveformStyle
    private let barColor: Color
    private let levelPublisher: AnyPublisher<Float, Never>?

    @State private var currentLevel: Float = 0.0

    // MARK: - Inits

    /// Initializer taking a real-time audio publisher.
    init(
        style: LiveAudioWaveformStyle = .bars,
        barColor: Color = .white,
        levelPublisher: AnyPublisher<Float, Never>
    ) {
        self.style = style
        self.barColor = barColor
        self.levelPublisher = levelPublisher
        _currentLevel = State(initialValue: 0.0)
    }

    /// Initializer taking an explicit static or binding-driven level.
    init(
        style: LiveAudioWaveformStyle = .bars,
        barColor: Color = .white,
        level: Float
    ) {
        self.style = style
        self.barColor = barColor
        self.levelPublisher = nil
        _currentLevel = State(initialValue: level)
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch style {
            case .bars:
                equalizerBarsView
            case .rings(let baseRadius):
                auraRingsView(baseRadius: baseRadius)
            }
        }
        .onReceive(levelPublisher ?? Empty().eraseToAnyPublisher()) { level in
            // Clamp and update with ultra-smooth spring
            withAnimation(.spring(response: 0.12, dampingFraction: 0.65)) {
                self.currentLevel = max(0.0, min(1.0, level))
            }
        }
    }

    // MARK: - Equalizer Bars View

    private var equalizerBarsView: some View {
        HStack(spacing: DS.Spacing.xxs) {
            ForEach(0..<5, id: \.self) { index in
                let scale = barHeightMultiplier(for: index)
                let height = max(4.0, CGFloat(currentLevel) * 26.0 * scale + 4.0)

                RoundedRectangle(cornerRadius: DS.Radius.pill)
                    .fill(barColor)
                    .frame(width: 3.5, height: height)
            }
        }
        .frame(height: 32)
    }

    // MARK: - Aura Rings View

    private func auraRingsView(baseRadius: CGFloat) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                let ringScale: CGFloat = 1.0 + CGFloat(index + 1) * 0.16 * CGFloat(max(0.15, currentLevel))
                let opacity: Double = Double(max(0.08, currentLevel * 0.55)) / Double(index + 1)

                Circle()
                    .stroke(barColor.opacity(opacity), lineWidth: 1.5)
                    .frame(width: baseRadius * ringScale, height: baseRadius * ringScale)
            }
        }
    }

    // MARK: - Multiplier Calculation

    private func barHeightMultiplier(for index: Int) -> CGFloat {
        // Natural audio spectrum distribution: middle bars bounce highest
        switch index {
        case 0: return 0.55
        case 1: return 0.85
        case 2: return 1.00
        case 3: return 0.75
        case 4: return 0.45
        default: return 0.60
        }
    }
}
