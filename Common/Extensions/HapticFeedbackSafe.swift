//
//  HapticFeedbackSafe.swift
//  Instagram
//
//  Created by Kiro on 15/10/26.
//

import UIKit
import CoreHaptics

// MARK: - HapticFeedbackSafe

/// Safe, high-performance haptic feedback helper:
/// - Guarantees zero `CHHapticPattern` Error 260 log spam on iOS Simulator.
/// - Caches hardware capabilities check to prevent repeated disk/driver lookups.
/// - Delivers crisp native haptics on physical iOS hardware.
public enum HapticFeedbackSafe {

    private static let isSupported: Bool = {
        #if targetEnvironment(simulator)
        return false
        #else
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
        #endif
    }()

    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isSupported else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    public static func selection() {
        guard isSupported else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isSupported else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
