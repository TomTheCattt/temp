//
//  AppTypography.swift
//  Instagram
//
//  Typography system based on Figma – Instagram UI Kit 4.0
//  Font: Instagram Sans (Regular, Medium, Semibold/Bold)
//

import SwiftUI

// MARK: - FontFamily

/// Instagram Sans font family names as registered in Info.plist.
enum FontFamily {
    static let regular  = "InstagramSans"
    static let medium   = "InstagramSans-Medium"
    static let bold     = "InstagramSans-Bold"
    static let light    = "InstagramSans-Light"
    static let headline = "InstagramSansHeadline"
}

// MARK: - AppTypography

/// Centralized typography tokens extracted from the Figma design system.
/// Usage: `AppTypography.title1Bold`, `AppTypography.bodyRegular`, etc.
///
/// Each style defines: font name, size (px), weight, and letter spacing (%).
enum AppTypography {

    // MARK: - Title 1 — 21px

    /// Title 1 Bold — 21px, Bold, letterSpacing 1%
    static let title1Bold = Font.custom(FontFamily.bold, size: 21)

    /// Title 1 Regular — 21px, Regular, letterSpacing 1%
    static let title1Regular = Font.custom(FontFamily.regular, size: 21)

    // MARK: - Title 2 — 15px

    /// Title 2 Bold — 15px, Bold, letterSpacing 0
    static let title2Bold = Font.custom(FontFamily.bold, size: 15)

    /// Title 2 Regular — 15px, Regular, letterSpacing 0
    static let title2Regular = Font.custom(FontFamily.regular, size: 15)

    // MARK: - Title 3 — 14px

    /// Title 3 Bold — 14px, Bold, letterSpacing 1%
    static let title3Bold = Font.custom(FontFamily.bold, size: 14)

    /// Title 3 Regular — 14px, Regular, letterSpacing 1%
    static let title3Regular = Font.custom(FontFamily.regular, size: 14)

    // MARK: - Headline — 13px

    /// Headline Bold — 13px, Semibold, letterSpacing 1%
    static let headlineBold = Font.custom(FontFamily.bold, size: 13)

    /// Headline Regular — 13px, Regular, letterSpacing 1%
    static let headlineRegular = Font.custom(FontFamily.regular, size: 13)

    // MARK: - Body — 13px

    /// Body Bold — 13px, Bold, letterSpacing 1%
    static let bodyBold = Font.custom(FontFamily.bold, size: 13)

    /// Body Regular — 13px, Regular, letterSpacing 2%
    static let bodyRegular = Font.custom(FontFamily.regular, size: 13)

    // MARK: - Callout — 12px

    /// Callout Bold — 12px, Medium, letterSpacing 2%
    static let calloutBold = Font.custom(FontFamily.medium, size: 12)

    /// Callout Regular — 12px, Regular, letterSpacing 2%
    static let calloutRegular = Font.custom(FontFamily.regular, size: 12)

    // MARK: - Footnote — 11px

    /// Footnote Semibold — 11px, Semibold, letterSpacing 2%
    static let footnoteSemibold = Font.custom(FontFamily.bold, size: 11)

    /// Footnote Regular — 11px, Regular, letterSpacing 3%
    static let footnoteRegular = Font.custom(FontFamily.regular, size: 11)

    // MARK: - Caption 1 — 10px

    /// Caption 1 Bold — 10px, Semibold, letterSpacing 4%
    static let caption1Bold = Font.custom(FontFamily.bold, size: 10)

    /// Caption 1 Regular — 10px, Regular, letterSpacing 4%
    static let caption1Regular = Font.custom(FontFamily.regular, size: 10)

    // MARK: - Caption 2 — 7px

    /// Caption 2 Bold — 7px, Semibold, letterSpacing 6%
    static let caption2Bold = Font.custom(FontFamily.bold, size: 7)

    /// Caption 2 Regular — 7px, Regular, letterSpacing 6%
    static let caption2Regular = Font.custom(FontFamily.regular, size: 7)

    // MARK: - Brand / Special

    /// Instagram brand logo text (Headline font).
    static let brandLogo = Font.custom(FontFamily.headline, size: 24)
}

// MARK: - Letter Spacing Values

/// Letter spacing percentages from Figma, converted to pt values.
/// Usage: `.tracking(LetterSpacing.percent1(forSize: 13))`
enum LetterSpacing {

    /// 0% letter spacing.
    static func percent0(forSize size: CGFloat) -> CGFloat { 0 }

    /// 1% letter spacing.
    static func percent1(forSize size: CGFloat) -> CGFloat { size * 0.01 }

    /// 2% letter spacing.
    static func percent2(forSize size: CGFloat) -> CGFloat { size * 0.02 }

    /// 3% letter spacing.
    static func percent3(forSize size: CGFloat) -> CGFloat { size * 0.03 }

    /// 4% letter spacing.
    static func percent4(forSize size: CGFloat) -> CGFloat { size * 0.04 }

    /// 6% letter spacing.
    static func percent6(forSize size: CGFloat) -> CGFloat { size * 0.06 }
}

// MARK: - Typography Style Descriptor

/// Complete typography style with all Figma properties for use in custom modifiers.
struct TypographyStyle {
    let font: Font
    let size: CGFloat
    let letterSpacingPercent: CGFloat // e.g., 0.01 for 1%

    var tracking: CGFloat {
        size * letterSpacingPercent
    }
}

extension AppTypography {

    // Pre-built TypographyStyle instances for when you need full control.

    static let title1BoldStyle      = TypographyStyle(font: title1Bold, size: 21, letterSpacingPercent: 0.01)
    static let title1RegularStyle   = TypographyStyle(font: title1Regular, size: 21, letterSpacingPercent: 0.01)
    static let title2BoldStyle      = TypographyStyle(font: title2Bold, size: 15, letterSpacingPercent: 0)
    static let title2RegularStyle   = TypographyStyle(font: title2Regular, size: 15, letterSpacingPercent: 0)
    static let title3BoldStyle      = TypographyStyle(font: title3Bold, size: 14, letterSpacingPercent: 0.01)
    static let title3RegularStyle   = TypographyStyle(font: title3Regular, size: 14, letterSpacingPercent: 0.01)
    static let headlineBoldStyle    = TypographyStyle(font: headlineBold, size: 13, letterSpacingPercent: 0.01)
    static let headlineRegularStyle = TypographyStyle(font: headlineRegular, size: 13, letterSpacingPercent: 0.01)
    static let bodyBoldStyle        = TypographyStyle(font: bodyBold, size: 13, letterSpacingPercent: 0.01)
    static let bodyRegularStyle     = TypographyStyle(font: bodyRegular, size: 13, letterSpacingPercent: 0.02)
    static let calloutBoldStyle     = TypographyStyle(font: calloutBold, size: 12, letterSpacingPercent: 0.02)
    static let calloutRegularStyle  = TypographyStyle(font: calloutRegular, size: 12, letterSpacingPercent: 0.02)
    static let footnoteSemiboldStyle = TypographyStyle(font: footnoteSemibold, size: 11, letterSpacingPercent: 0.02)
    static let footnoteRegularStyle = TypographyStyle(font: footnoteRegular, size: 11, letterSpacingPercent: 0.03)
    static let caption1BoldStyle    = TypographyStyle(font: caption1Bold, size: 10, letterSpacingPercent: 0.04)
    static let caption1RegularStyle = TypographyStyle(font: caption1Regular, size: 10, letterSpacingPercent: 0.04)
    static let caption2BoldStyle    = TypographyStyle(font: caption2Bold, size: 7, letterSpacingPercent: 0.06)
    static let caption2RegularStyle = TypographyStyle(font: caption2Regular, size: 7, letterSpacingPercent: 0.06)
}

// MARK: - Font to UIFont Conversion

import UIKit

extension TypographyStyle {
    /// Convert the typography style to a `UIFont` for use in UIKit contexts.
    ///
    /// Example:
    /// ```swift
    /// let uiFont = AppTypography.bodyBoldStyle.uiFont
    /// label.font = uiFont
    /// ```
    var uiFont: UIFont {
        UIFont.appFont(name: fontName, size: size)
    }

    /// The underlying font family name derived from size and style.
    private var fontName: String {
        // Map back from the Font to the registered font name
        // by checking which FontFamily was used based on the style font
        // We use a helper that reconstructs from size + weight
        let descriptor = UIFontDescriptor(name: "", size: size)
        return descriptor.postscriptName
    }
}

extension UIFont {
    /// Create a UIFont from the app's custom font family.
    /// Falls back to system font if the custom font isn't available.
    static func appFont(name: String, size: CGFloat) -> UIFont {
        UIFont(name: name, size: size) ?? .systemFont(ofSize: size)
    }

    // MARK: - Title 1 — 21px

    static let title1Bold = UIFont.appFont(name: FontFamily.bold, size: 21)
    static let title1Regular = UIFont.appFont(name: FontFamily.regular, size: 21)

    // MARK: - Title 2 — 15px

    static let title2Bold = UIFont.appFont(name: FontFamily.bold, size: 15)
    static let title2Regular = UIFont.appFont(name: FontFamily.regular, size: 15)

    // MARK: - Title 3 — 14px

    static let title3Bold = UIFont.appFont(name: FontFamily.bold, size: 14)
    static let title3Regular = UIFont.appFont(name: FontFamily.regular, size: 14)

    // MARK: - Headline — 13px

    static let headlineBold = UIFont.appFont(name: FontFamily.bold, size: 13)
    static let headlineRegular = UIFont.appFont(name: FontFamily.regular, size: 13)

    // MARK: - Body — 13px

    static let bodyBold = UIFont.appFont(name: FontFamily.bold, size: 13)
    static let bodyRegular = UIFont.appFont(name: FontFamily.regular, size: 13)

    // MARK: - Callout — 12px

    static let calloutBold = UIFont.appFont(name: FontFamily.medium, size: 12)
    static let calloutRegular = UIFont.appFont(name: FontFamily.regular, size: 12)

    // MARK: - Footnote — 11px

    static let footnoteSemibold = UIFont.appFont(name: FontFamily.bold, size: 11)
    static let footnoteRegular = UIFont.appFont(name: FontFamily.regular, size: 11)

    // MARK: - Caption 1 — 10px

    static let caption1Bold = UIFont.appFont(name: FontFamily.bold, size: 10)
    static let caption1Regular = UIFont.appFont(name: FontFamily.regular, size: 10)

    // MARK: - Caption 2 — 7px

    static let caption2Bold = UIFont.appFont(name: FontFamily.bold, size: 7)
    static let caption2Regular = UIFont.appFont(name: FontFamily.regular, size: 7)

    // MARK: - Brand / Special

    static let brandLogo = UIFont.appFont(name: FontFamily.headline, size: 24)
}

// MARK: - View Modifier

/// Apply a full typography style (font + tracking) in one modifier.
struct TypographyModifier: ViewModifier {
    let style: TypographyStyle

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .tracking(style.tracking)
    }
}

extension View {
    /// Apply a complete typography style from the design system.
    ///
    /// Example:
    /// ```swift
    /// Text("Hello")
    ///     .typography(AppTypography.headlineBoldStyle)
    /// ```
    func typography(_ style: TypographyStyle) -> some View {
        modifier(TypographyModifier(style: style))
    }
}
