//
//  ColorTokens.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - ColorTokens

/// Semantic color tokens for consistent theming across the app.
/// All colors adapt automatically to light/dark mode using SwiftUI's adaptive colors.
enum ColorTokens {

    // MARK: - Background

    /// Primary background (main content area).
    static let backgroundPrimary = Color(.systemBackground)

    /// Secondary background (grouped sections, cards).
    static let backgroundSecondary = Color(.secondarySystemBackground)

    /// Tertiary background (nested groups).
    static let backgroundTertiary = Color(.tertiarySystemBackground)

    /// Elevated background (sheets, modals).
    static let backgroundElevated = Color(.systemBackground)

    // MARK: - Surface

    /// Card/cell surface.
    static let surface = Color(.secondarySystemBackground)

    /// Elevated surface (floating elements).
    static let surfaceElevated = Color(.tertiarySystemBackground)

    // MARK: - Text

    /// Primary text.
    static let textPrimary = Color(.label)

    /// Secondary text (subtitles, captions).
    static let textSecondary = Color(.secondaryLabel)

    /// Tertiary text (placeholders, disabled).
    static let textTertiary = Color(.tertiaryLabel)

    /// Inverted text (on colored backgrounds).
    static let textInverted = Color.white

    // MARK: - Separator

    /// Standard separator.
    static let separator = Color(.separator)

    /// Opaque separator.
    static let separatorOpaque = Color(.opaqueSeparator)

    // MARK: - Brand

    /// Instagram gradient start.
    static let brandGradientStart = Color(red: 0.88, green: 0.19, blue: 0.66) // #E1306C

    /// Instagram gradient middle.
    static let brandGradientMid = Color(red: 0.99, green: 0.27, blue: 0.27) // #FD1D1D

    /// Instagram gradient end.
    static let brandGradientEnd = Color(red: 0.97, green: 0.71, blue: 0.20) // #F77737

    /// Instagram blue (links, buttons).
    static let brandBlue = Color(red: 0.22, green: 0.58, blue: 0.89) // #3897F0

    // MARK: - Accent

    /// Primary accent (buttons, links).
    static let accentPrimary = Color.blue

    /// Destructive (delete, report).
    static let destructive = Color.red

    /// Success (confirmed, sent).
    static let success = Color.green

    /// Warning.
    static let warning = Color.orange

    // MARK: - Interactive

    /// Button background (primary CTA).
    static let buttonPrimary = Color.blue

    /// Button background (secondary).
    static let buttonSecondary = Color(.systemGray5)

    /// Button disabled.
    static let buttonDisabled = Color(.systemGray4)

    // MARK: - Special

    /// Story ring gradient.
    static var storyGradient: LinearGradient {
        LinearGradient(
            colors: [brandGradientEnd, brandGradientStart, Color.purple],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    /// Like heart color.
    static let likeRed = Color.red

    /// Verified badge.
    static let verifiedBlue = Color.blue

    /// Unread badge.
    static let badgeRed = Color.red

    // MARK: - Shadows

    /// Light shadow for cards.
    static let shadowLight = Color.black.opacity(0.05)

    /// Medium shadow.
    static let shadowMedium = Color.black.opacity(0.1)
}

// MARK: - Legacy Aliases (use DS.* instead for new code)

/// @available: Use `DS.Font.*` instead.
typealias FontTokens = DS.Font
/// @available: Use `DS.Spacing.*` instead.
typealias SpacingTokens = DS.Spacing
/// @available: Use `DS.Radius.*` instead.
typealias CornerRadiusTokens = DS.Radius
