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

// MARK: - AppChangeEffect

/// Predefined change effects (triggered when a value changes).
enum AppChangeEffect {

    /// Spray particles outward (like confetti on a like button).
    static func spray(origin: UnitPoint = .center) -> some ChangeEffect {
        .spray(origin: origin) {
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
        }
    }

    /// Rise particles upward.
    static var rise: some ChangeEffect {
        .rise(origin: .center) {
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
        }
    }

    /// Haptic feedback pulse.
    static var hapticFeedback: some ChangeEffect {
        .feedback(hapticNotification: .success)
    }

    /// Shine sweep effect.
    static var shine: some ChangeEffect {
        .shine
    }

    /// Glow highlight.
    static var glow: some ChangeEffect {
        .glow(color: .blue, radius: 10)
    }

    /// Pulse scale effect.
    static var pulse: some ChangeEffect {
        .pulse(shape: Circle(), style: .cyan, count: 2)
    }

    /// Jump effect.
    static var jump: some ChangeEffect {
        .jump(height: 50)
    }

    /// Shake (error feedback).
    static var shake: some ChangeEffect {
        .shake(rate: .fast)
    }

    /// Spin effect.
    static var spin: some ChangeEffect {
        .spin(axis: (x: 0, y: 1, z: 0))
    }
}

// MARK: - View Extensions

extension View {

    /// Apply a Pow transition when appearing/disappearing.
    ///
    /// Usage:
    /// ```swift
    /// if showCard {
    ///     CardView()
    ///         .appTransition(.pop)
    /// }
    /// ```
    func appTransition(_ transition: AnyTransition) -> some View {
        self.transition(transition)
    }

    /// Trigger a change effect when a value changes.
    ///
    /// Usage:
    /// ```swift
    /// Image(systemName: "heart.fill")
    ///     .appChangeEffect(.spray(), trigger: likeCount)
    /// ```
    func appChangeEffect<E: ChangeEffect, V: Equatable>(
        _ effect: E,
        trigger: V
    ) -> some View {
        self.changeEffect(effect, value: trigger)
    }

    /// Conditional repeat effect (continuous animation).
    ///
    /// Usage:
    /// ```swift
    /// NotificationBadge()
    ///     .appRepeatEffect(.pulse, isActive: hasNotification)
    /// ```
    func appRepeatEffect<E: ChangeEffect>(
        _ effect: E,
        isActive: Bool
    ) -> some View {
        self.changeEffect(effect, value: isActive, isEnabled: isActive)
    }

    // MARK: - Common Presets

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

    /// Success feedback (scale pulse + haptic).
    func successFeedback<V: Equatable>(trigger: V) -> some View {
        self
            .changeEffect(.feedback(hapticNotification: .success), value: trigger)
            .changeEffect(.pulse(shape: Circle(), style: .green, count: 1), value: trigger)
    }

    /// Error shake animation.
    func errorShake<V: Equatable>(trigger: V) -> some View {
        self.changeEffect(.shake(rate: .fast), value: trigger)
    }

    /// Notification badge pulse.
    func notificationPulse(isActive: Bool) -> some View {
        self.changeEffect(
            .pulse(shape: Circle(), style: .red, count: 3),
            value: isActive,
            isEnabled: isActive
        )
    }
}
