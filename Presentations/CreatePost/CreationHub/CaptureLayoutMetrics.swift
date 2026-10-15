//
//  CaptureLayoutMetrics.swift
//  Instagram
//

import CoreGraphics

/// Shared geometry for camera capture modes that live under the creation-hub
/// switcher. Mode-specific tools may differ, but their capture controls must
/// share the same optical baseline.
enum CaptureLayoutMetrics {
    static let modeSwitcherClearance: CGFloat = 78
}
