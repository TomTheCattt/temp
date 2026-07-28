//
//  AnimationModifier.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import Pow

// MARK: - AppTransition

/// Predefined transitions wrapping Pow for consistent use across the app.
enum AppTransition {

    // MARK: - Appear/Disappear

    /// Smooth move-in from an edge.
    static func moveIn(edge: Edge = .bottom) -> AnyTransition {
        .movingParts.move(edge: edge)
    }

    /// Pop-in scale effect.
    static var pop: AnyTransition {
        .movingParts.pop(.white)
    }

    /// Blur transition.
    static var blur: AnyTransition {
        .movingParts.blur
    }

    /// Glare (shine) effect.
    static var glare: AnyTransition {
        .movingParts.glare(angle: .degrees(225), color: .white)
    }

    /// Wipe from an edge.
    static func wipe(edge: Edge = .leading) -> AnyTransition {
        .movingParts.wipe(angle: wipeAngle(for: edge), blurRadius: 15)
    }

    /// Flip effect.
    static var flip: AnyTransition {
        .movingParts.flip
    }

    /// Swoosh effect.
    static var swoosh: AnyTransition {
        .movingParts.swoosh
    }

    /// Boing (spring bounce) effect.
    static var boing: AnyTransition {
        .movingParts.boing
    }

    /// Iris (circular reveal).
    static var iris: AnyTransition {
        .movingParts.iris(blurRadius: 10)
    }

    // MARK: - Helpers

    private static func wipeAngle(for edge: Edge) -> Angle {
        switch edge {
        case .top:      return .degrees(270)
        case .leading:  return .degrees(180)
        case .bottom:   return .degrees(90)
        case .trailing: return .degrees(0)
        }
    }
}

// MARK: - View Extensions

extension View {

    /// Apply a Pow transition when appearing/disappearing.
    func appTransition(_ transition: AnyTransition) -> some View {
        self.transition(transition)
    }

    // MARK: - Common Change Effect Presets

    /// Like button spray animation.
    func likeEffect(trigger: Int) -> some View {
        self.changeEffect(
            .spray(origin: .center) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
            },
            value: trigger
        )
    }

    /// Success feedback (haptic).
    func successFeedback<V: Equatable>(trigger: V) -> some View {
        self.changeEffect(.feedback(hapticNotification: .success), value: trigger)
    }

    /// Error shake animation.
    func errorShake<V: Equatable>(trigger: V) -> some View {
        self.changeEffect(.shake(rate: .fast), value: trigger)
    }

    /// Shine sweep effect on change.
    func shineEffect<V: Equatable>(trigger: V) -> some View {
        self.changeEffect(.shine, value: trigger)
    }

    /// Glow highlight on change.
    func glowEffect<V: Equatable>(trigger: V, color: Color = .blue) -> some View {
        self.changeEffect(.glow(color: color, radius: 10), value: trigger)
    }

    /// Pulse effect (notification badge).
    func pulseEffect<V: Equatable>(trigger: V, color: Color = .red) -> some View {
        self.changeEffect(
            .pulse(shape: Circle(), style: color, count: 2),
            value: trigger
        )
    }

    /// Jump effect.
    func jumpEffect<V: Equatable>(trigger: V) -> some View {
        self.changeEffect(.jump(height: 50), value: trigger)
    }

    /// Spin effect.
    func spinEffect<V: Equatable>(trigger: V) -> some View {
        self.changeEffect(.spin(axis: (x: 0, y: 1, z: 0)), value: trigger)
    }

    /// Rise particles upward.
    func riseEffect(trigger: Int) -> some View {
        self.changeEffect(
            .rise(origin: .center) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
            },
            value: trigger
        )
    }

    /// Continuous pulse for badges/indicators.
    func continuousPulse(isActive: Bool, color: Color = .red) -> some View {
        self.changeEffect(
            .pulse(shape: Circle(), style: color, count: 3),
            value: isActive,
            isEnabled: isActive
        )
    }
}
