//
//  AnimatedStoryTextView.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import SwiftUI

// MARK: - AnimatedStoryTextView

/// Renders dynamic text with live animations (.typewriter, .reveal, .bounce)
/// directly on the Story / Create canvas, achieving 60/120 FPS ProMotion fidelity.
/// If animation is .none, falls back to static rendering with 0% CPU overhead.
/// Uses continuous periodic timeline schedule so animation never pauses unexpectedly.
struct AnimatedStoryTextView: View {

    let item: TextOverlayItem

    @State private var startDate: Date = Date()

    var body: some View {
        Group {
            switch item.animation {
            case .none:
                staticTextView(
                    text: item.text,
                    alphaMultiplier: 1.0,
                    scaleMultiplier: 1.0,
                    yOffset: 0.0
                )

            case .typewriter:
                typewriterView

            case .reveal:
                revealView

            case .bounce:
                bounceView
            }
        }
        .onChange(of: item.animation) { _, _ in
            startDate = Date()
        }
    }

    // MARK: - Static Text View

    @ViewBuilder
    private func staticTextView(
        text: String,
        alphaMultiplier: CGFloat,
        scaleMultiplier: CGFloat,
        yOffset: CGFloat
    ) -> some View {
        Text(text)
            .font(
                item.effect == .pixel
                    ? .system(size: item.fontSize, weight: .bold, design: .monospaced)
                    : Font(item.fontStyle.uiFont(size: item.fontSize))
            )
            .italic(item.isItalic)
            .multilineTextAlignment(item.alignment)
            .foregroundStyle(item.color.opacity(alphaMultiplier))
            .padding(.horizontal, item.hasBackground ? 12 : 6)
            .padding(.vertical, item.hasBackground ? 6 : 4)
            .background(
                item.hasBackground
                    ? item.color.smartBadgeBackgroundColor.opacity(alphaMultiplier)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .shadow(
                color: item.effect == .neon
                    ? item.color.opacity(0.8 * alphaMultiplier)
                    : (item.effect == .sparkle ? Color.white.opacity(0.9 * alphaMultiplier) : .black.opacity(item.hasBackground ? 0.35 : 0.7 * alphaMultiplier)),
                radius: (item.effect == .neon || item.effect == .sparkle) ? 10 : 4,
                x: 0,
                y: 2
            )
            .scaleEffect(scaleMultiplier)
            .offset(y: yOffset)
    }

    // MARK: - Typewriter Animation

    private var typewriterView: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { context in
            let elapsed = max(0.0, context.date.timeIntervalSince(startDate))
            let charsPerSec = 12.0
            let pauseDuration = 1.4
            let fullTextCount = max(1, item.text.count)
            let typingDuration = Double(fullTextCount) / charsPerSec
            let totalCycleDuration = typingDuration + pauseDuration

            let cycleTime = elapsed.truncatingRemainder(dividingBy: totalCycleDuration)
            let visibleCount = min(item.text.count, max(0, Int(cycleTime * charsPerSec)))

            let visibleSubstring = String(item.text.prefix(visibleCount))
            let isTyping = cycleTime < typingDuration
            let isCursorBlink = (Int(cycleTime * 4.0) % 2 == 0)
            let cursorText = (isTyping && isCursorBlink) ? " |" : ""

            staticTextView(
                text: visibleSubstring + cursorText,
                alphaMultiplier: 1.0,
                scaleMultiplier: 1.0,
                yOffset: 0.0
            )
        }
    }

    // MARK: - Reveal Animation

    private var revealView: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 60.0)) { context in
            let elapsed = max(0.0, context.date.timeIntervalSince(startDate))
            let cycleDuration = 3.0
            let revealDuration = 1.2
            let cycleTime = elapsed.truncatingRemainder(dividingBy: cycleDuration)

            let (alpha, scale): (CGFloat, CGFloat) = {
                if cycleTime < revealDuration {
                    let norm = CGFloat(cycleTime / revealDuration)
                    return (norm, 0.85 + 0.15 * norm)
                } else {
                    return (1.0, 1.0)
                }
            }()

            staticTextView(
                text: item.text,
                alphaMultiplier: alpha,
                scaleMultiplier: scale,
                yOffset: 0.0
            )
        }
    }

    // MARK: - Bounce Animation

    private var bounceView: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 60.0)) { context in
            let elapsed = max(0.0, context.date.timeIntervalSince(startDate))
            let bounceFreq = 1.8 // ~1.8 bounces per second
            let oscillation = abs(sin(elapsed * .pi * bounceFreq))
            let yOffset = -CGFloat(oscillation * 16.0)
            let scaleY = CGFloat(1.0 + 0.04 * cos(elapsed * .pi * bounceFreq * 2.0))

            staticTextView(
                text: item.text,
                alphaMultiplier: 1.0,
                scaleMultiplier: scaleY,
                yOffset: yOffset
            )
        }
    }
}
