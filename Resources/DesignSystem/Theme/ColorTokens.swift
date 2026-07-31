//
//  ColorTokens.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - ColorTokens

/// Semantic color tokens for consistent theming across the app.
/// Maps design intent to primitive colors from Figma.
/// All colors adapt automatically to light/dark mode.
enum ColorTokens {

    // MARK: - Background

    /// Primary background (main content area).
    /// Light: white | Dark: gray100
    static let backgroundPrimary = Color(.backgroundPrimary)

    /// Secondary background (grouped sections, cards).
    /// Light: gray10 | Dark: gray90
    static let backgroundSecondary = Color(.backgroundSecondary)

    /// Tertiary background (nested groups).
    /// Light: gray20 | Dark: gray80
    static let backgroundTertiary = Color(.tertiarySystemBackground)

    /// Elevated background (sheets, modals).
    static let backgroundElevated = Color(.systemBackground)
    
    /// Background subtler.
    static let backgroundSubtler = Color(.backgroundSubtler)

    // MARK: - Surface

    /// Card/cell surface.
    static let surface = Color(.secondarySystemBackground)

    /// Elevated surface (floating elements).
    static let surfaceElevated = Color(.tertiarySystemBackground)

    // MARK: - Text

    /// Primary text — Light: Black 100 | Dark: White 100.
    static let textPrimary = Color(.textPrimary)

    /// Secondary text (subtitles, captions) — Light: Gray 60 | Dark: Gray 40.
    static let textSecondary = Color(.textSecondary)

    /// Tertiary text (placeholders, disabled) — Light: Gray 40 | Dark: Gray 60.
    static let textTertiary = Color(.textTertiary)

    /// Inverted text (on colored/brand backgrounds).
    static let textInverted = PrimitiveColors.Neutral.white100

    // MARK: - Separator

    /// Standard separator — Gray 30 / Gray 80.
    static let separator = Color(.separator)

    /// Opaque separator.
    static let separatorOpaque = Color(.opaqueSeparator)

    // MARK: - Brand (from Figma Instagram gradient)

    /// Instagram gradient — Purple 80.
    static let brandPurple = PrimitiveColors.Purple.purple80 // #7638FA

    /// Instagram gradient — Magenta 100.
    static let brandMagenta = PrimitiveColors.Magenta.magenta100 // #D300C5

    /// Instagram gradient — Pink 100.
    static let brandPink = PrimitiveColors.Pink.pink100 // #FF0069

    /// Instagram gradient — Orange 100.
    static let brandOrange = PrimitiveColors.Orange.orange100 // #FF7A00

    /// Instagram gradient — Yellow 100.
    static let brandYellow = PrimitiveColors.Yellow.yellow100 // #FFD600

    /// Legacy alias: gradient start (pink).
    static let brandGradientStart = PrimitiveColors.Pink.pink100

    /// Legacy alias: gradient middle (magenta).
    static let brandGradientMid = PrimitiveColors.Magenta.magenta100

    /// Legacy alias: gradient end (orange).
    static let brandGradientEnd = PrimitiveColors.Orange.orange100

    /// Instagram blue (links, buttons) — Blue 60.
    static let brandBlue = PrimitiveColors.Blue.blue60 // #0098FD

    // MARK: - Accent

    /// Primary accent (buttons, links) — Blue 60.
    static let accentPrimary = PrimitiveColors.Blue.blue60

    /// Destructive (delete, report) — Red 100.
    static let destructive = PrimitiveColors.Red.red100

    /// Success (confirmed, sent) — Green 100.
    static let success = PrimitiveColors.Green.green100

    /// Warning — Orange 100.
    static let warning = PrimitiveColors.Orange.orange100

    // MARK: - Interactive

    /// Button background (primary CTA) — Blue 60.
    static let buttonPrimary = PrimitiveColors.Blue.blue60

    /// Button background (secondary) — Gray 20.
    static let buttonSecondary = PrimitiveColors.Gray.gray20

    /// Button disabled — Gray 30.
    static let buttonDisabled = PrimitiveColors.Gray.gray30

    // MARK: - Special

    /// Story ring gradient (matches Figma Instagram gradient).
    static var storyGradient: LinearGradient {
        LinearGradient(
            colors: PrimitiveColors.instagramGradientColors,
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    /// Like heart color — Red 100.
    static let likeRed = PrimitiveColors.Red.red100

    /// Verified badge — Blue 60.
    static let verifiedBlue = PrimitiveColors.Blue.blue60

    /// Unread badge — Red 100.
    static let badgeRed = PrimitiveColors.Red.red100

    // MARK: - Shadows

    /// Light shadow for cards.
    static let shadowLight = PrimitiveColors.Neutral.black100.opacity(0.05)

    /// Medium shadow.
    static let shadowMedium = PrimitiveColors.Neutral.black100.opacity(0.10)

    // MARK: - Overlay

    /// Dark overlay (behind modals, sheets).
    static let overlayDark = PrimitiveColors.Neutral.black60

    /// Light overlay.
    static let overlayLight = PrimitiveColors.Neutral.black40
    
    // MARK: - Stroke
    
    /// Stroke (for border).
    static let stroke = Color.stroke
}

// MARK: - Legacy Aliases (use DS.* instead for new code)

/// @available: Use `DS.Font.*` instead.
typealias FontTokens = DS.Font
/// @available: Use `DS.Spacing.*` instead.
typealias SpacingTokens = DS.Spacing
/// @available: Use `DS.Radius.*` instead.
typealias CornerRadiusTokens = DS.Radius
