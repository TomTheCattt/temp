//
//  DesignConstants.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - DS (Design System Namespace)

/// Centralized design constants.
/// Usage: `DS.Spacing.md`, `DS.Font.username`, `DS.Size.avatarMedium`, etc.
/// NEVER hard-code numeric values in Views — always reference DS.
nonisolated enum DS {

    // MARK: - Spacing (padding, margins, gaps)

    enum Spacing {
        /// 1pt — hairline (grid gutters, 1px underlines/dividers).
        static let hairline: CGFloat = 1
        /// 2pt — hairline gaps.
        static let xxxs: CGFloat = 2
        /// 4pt — tight inner padding.
        static let xxs: CGFloat = 4
        /// 6pt — between icon and label.
        static let iconGap: CGFloat = 6
        /// 8pt — compact padding.
        static let xs: CGFloat = 8
        /// 10pt — input field vertical padding.
        static let inputVertical: CGFloat = 10
        /// 12pt — standard small gap.
        static let sm: CGFloat = 12
        /// 14pt — between sections in forms.
        static let formGap: CGFloat = 14
        /// 16pt — standard horizontal padding.
        static let md: CGFloat = 16
        /// 20pt — section spacing.
        static let lg: CGFloat = 20
        /// 24pt — large section gap.
        static let xl: CGFloat = 24
        /// 32pt — screen section dividers.
        static let xxl: CGFloat = 32
        /// 30pt — media control cluster bottom inset.
        static let mediaControlsBottom: CGFloat = 30
        /// 40pt — extra large.
        static let xxxl: CGFloat = 40
        /// 48pt — modal top padding.
        static let modalTop: CGFloat = 48
        /// 60pt — picture-in-picture top inset.
        static let pipTop: CGFloat = 60
    }

    // MARK: - Padding (screen-level)

    enum Padding {
        /// Standard horizontal screen padding.
        static let horizontal: CGFloat = 16
        /// Content padding on cards/posts.
        static let content: CGFloat = 12
        /// Compact padding (small cells).
        static let compact: CGFloat = 8
        /// Large padding (headers, hero areas).
        static let large: CGFloat = 24
        /// Huge padding (headers, hero areas).
        static let huge: CGFloat = 32
        /// Bottom safe area inset padding.
        static let bottomSafe: CGFloat = 34
        /// Input bar padding.
        static let inputBar: CGFloat = 10
    }

    // MARK: - Size (fixed element dimensions)

    enum Size {
        // Avatars
        /// 24pt — tiny inline avatar (replies, mini references).
        static let avatarXSmall: CGFloat = 24
        /// 28pt — message bubble avatar.
        static let avatarSmall: CGFloat = 28
        /// 32pt — story header, comment row.
        static let avatarCompact: CGFloat = 32
        /// 36pt — post header.
        static let avatarMedium: CGFloat = 36
        /// 44pt — list rows (followers, likes, DM).
        static let avatarList: CGFloat = 44
        /// 56pt — story circle in bar.
        static let avatarStoryCircle: CGFloat = 56
        /// 64pt — hashtag/profile header icon.
        static let avatarLarge: CGFloat = 64
        /// 80pt — edit profile avatar.
        static let avatarXLarge: CGFloat = 80
        /// 120pt — profile page header.
        static let avatarHero: CGFloat = 120

        // Icons
        /// 12pt — badge dot.
        static let iconXSmall: CGFloat = 12
        /// 16pt — inline icons.
        static let iconSmall: CGFloat = 16
        /// 20pt — action bar icons.
        static let iconMedium: CGFloat = 20
        /// 24pt — standard icon.
        static let iconDefault: CGFloat = 24
        /// 28pt — nav bar icons.
        static let iconLarge: CGFloat = 28
        /// 32pt — floating action.
        static let iconXLarge: CGFloat = 32
        /// 48pt — empty state icons.
        static let iconHero: CGFloat = 48
        /// 64pt — large empty state / onboarding.
        static let iconJumbo: CGFloat = 64

        // Buttons
        /// 30pt — small pill button height.
        static let buttonSmallHeight: CGFloat = 30
        /// 36pt — compact button height.
        static let buttonCompactHeight: CGFloat = 36
        /// 44pt — standard button / tap target (Apple HIG minimum).
        static let buttonDefaultHeight: CGFloat = 44
        /// 50pt — large CTA button.
        static let buttonLargeHeight: CGFloat = 50

        // Input
        /// 36pt — search bar height.
        static let searchBarHeight: CGFloat = 36
        /// 44pt — text field height.
        static let textFieldHeight: CGFloat = 44
        /// 48pt — message input bar.
        static let inputBarHeight: CGFloat = 48

        // Media
        /// 72pt — capture button diameter.
        static let captureButton: CGFloat = 72
        /// 60pt — capture button inner.
        static let captureButtonInner: CGFloat = 60
        /// 150pt — filter thumbnail.
        static let filterThumbnail: CGFloat = 150
        /// 120pt — grid cell minimum height.
        static let gridCellMinHeight: CGFloat = 120

        // Call
        /// 100pt — call screen caller avatar.
        static let avatarCall: CGFloat = 100
        /// 70pt — incoming call action button.
        static let callButtonLarge: CGFloat = 70
        /// 65pt — active call hangup button.
        static let callButtonMedium: CGFloat = 65
        /// 120pt — picture-in-picture width.
        static let pipWidth: CGFloat = 120
        /// 160pt — picture-in-picture height.
        static let pipHeight: CGFloat = 160

        // Story overlays
        /// 24pt — stacked viewer avatar.
        static let viewerAvatar: CGFloat = 24
        /// 36pt — stacked viewer avatar cluster width.
        static let viewerAvatarCluster: CGFloat = 36
        /// 80pt — story poll option button width.
        static let pollButtonWidth: CGFloat = 80
        /// 72pt — create-post filter thumbnail tile.
        static let filterThumbnailTile: CGFloat = 72

        /// 200pt — chat image message bubble.
        static let chatImageBubble: CGFloat = 200
        /// 180pt — chat audio message bubble width.
        static let chatAudioBubbleWidth: CGFloat = 180
        /// 200pt — chat video message bubble width.
        static let chatVideoBubbleWidth: CGFloat = 200
        /// 150pt — chat video message bubble height.
        static let chatVideoBubbleHeight: CGFloat = 150
        /// 60pt — revealed timestamp column width (iMessage-style drag reveal).
        static let chatTimestampWidth: CGFloat = 60
        /// 60pt — min horizontal spacer opposite a chat bubble.
        static let chatBubbleSpacer: CGFloat = 60
        /// 40pt — like/heart reaction emoji glyph size.
        static let chatLikeEmoji: CGFloat = 40

        // Skeleton / placeholders
        /// 150pt — skeleton text line width.
        static let skeletonLineWidth: CGFloat = 150
        /// 300pt — media picker preview min height.
        static let mediaPreviewMinHeight: CGFloat = 300
        /// 350pt — selected media preview max height.
        static let mediaPreviewMaxHeight: CGFloat = 350
        /// 400pt — editor/filter media preview height.
        static let mediaEditorPreviewHeight: CGFloat = 400
        /// 60pt — media viewer logo/icon size.
        static let mediaLogo: CGFloat = 60

        // Misc
        /// 3pt — grid spacing.
        static let gridSpacing: CGFloat = 2
        /// 30pt — audio disc (reels).
        static let audioDisc: CGFloat = 30
        /// 44pt — top status bar / safe area extension height.
        static let navBarStatusBarHeight: CGFloat = 44
    }

    // MARK: - CornerRadius

    enum Radius {
        /// 4pt — small elements (thumbnails, tags).
        static let small: CGFloat = 4
        /// 6pt — thumbnail cards.
        static let thumbnailCard: CGFloat = 6
        /// 8pt — buttons, cards.
        static let medium: CGFloat = 8
        /// 10pt — input fields, search bars.
        static let input: CGFloat = 10
        /// 12pt — sheets, media containers.
        static let large: CGFloat = 12
        /// 16pt — modal corners.
        static let xl: CGFloat = 16
        /// 18pt — message bubbles.
        static let bubble: CGFloat = 18
        /// 20pt — bottom sheets.
        static let sheet: CGFloat = 20
        /// 999pt — pill / fully rounded.
        static let pill: CGFloat = 999
    }

    // MARK: - Font (typography)

    /// Typography tokens backed by Instagram Sans custom font.
    /// Maps semantic names to `AppTypography` styles.
    enum Font {
        // MARK: Scale

        /// 25pt bold — large titles (Settings, Profile).
        static let largeTitle = AppTypography.title1Bold
        /// 21pt regular — large title regular variant.
        static let largeTitleRegular = AppTypography.title1Regular
        /// 15pt bold — section titles.
        static let title = AppTypography.title2Bold
        /// 15pt regular — section title regular variant.
        static let titleRegular = AppTypography.title2Regular
        /// 14pt bold — sub-titles.
        static let title3 = AppTypography.title3Bold
        /// 14pt regular — sub-title regular variant.
        static let title3Regular = AppTypography.title3Regular
        /// 13pt semibold — headlines.
        static let headline = AppTypography.headlineBold
        /// 13pt regular — subheadlines.
        static let subheadline = AppTypography.headlineRegular
        /// 13pt semibold — bold subheadline.
        static let subheadlineBold = AppTypography.headlineBold
        /// 13pt regular — body text.
        static let body = AppTypography.bodyRegular
        /// 13pt bold — body bold.
        static let bodyBold = AppTypography.bodyBold
        /// 12pt regular — callout.
        static let callout = AppTypography.calloutRegular
        /// 12pt medium — callout bold.
        static let calloutBold = AppTypography.calloutBold
        /// 11pt regular — footnote, captions, timestamps.
        static let caption = AppTypography.footnoteRegular
        /// 11pt semibold — bold caption (likes count, reply).
        static let captionBold = AppTypography.footnoteSemibold
        /// 10pt regular — tiny labels.
        static let caption2 = AppTypography.caption1Regular
        /// 10pt semibold — tiny bold labels (filter names, tab bar).
        static let caption2Bold = AppTypography.caption1Bold

        // MARK: Instagram-specific

        /// Username display (15pt bold).
        static let username = AppTypography.title2Bold
        /// Nav bar brand title (Instagram Sans Headline 24pt).
        static let navBrand = AppTypography.brandLogo
        /// Feed action count (13pt bold).
        static let actionCount = AppTypography.bodyBold
        /// Story username (10pt regular).
        static let storyLabel = AppTypography.caption1Regular
        /// Tab bar label (10pt regular).
        static let tabLabel = AppTypography.caption1Regular
        /// Comment text (13pt regular).
        static let commentText = AppTypography.bodyRegular
        /// Message text (13pt regular).
        static let messageText = AppTypography.bodyRegular
        /// Bio text (13pt regular).
        static let bioText = AppTypography.bodyRegular
        /// Stats number (14pt bold).
        static let statNumber = AppTypography.title3Bold
        /// Stats label (11pt regular).
        static let statLabel = AppTypography.footnoteRegular
    }

    // MARK: - Opacity

    enum Opacity {
        /// Full opacity.
        static let full: Double = 1.0
        /// High emphasis.
        static let high: Double = 0.87
        /// Medium emphasis (secondary text).
        static let medium: Double = 0.6
        /// Low emphasis (disabled, placeholder).
        static let low: Double = 0.38
        /// Overlay background.
        static let overlay: Double = 0.5
        /// Dimming behind the action HUD (ProgressHUD background).
        static let hudBackground: Double = 0.3
        /// Faint tint (error banner background wash).
        static let faint: Double = 0.08
        /// Subtle background tint.
        static let subtle: Double = 0.1
        /// Divider / border.
        static let divider: Double = 0.12
        /// Placeholder / skeleton fill.
        static let placeholder: Double = 0.2
        /// Track behind a progress fill (story progress bar).
        static let track: Double = 0.35
        /// Muted media element (dimmed avatar ring, secondary fill).
        static let muted: Double = 0.4
        /// Strong overlay content (secondary labels on media).
        static let strong: Double = 0.7
        /// Near-opaque overlay control (close buttons on media).
        static let nearOpaque: Double = 0.8
    }

    // MARK: - FontSize (system-font sizing on media overlays)

    /// Point sizes for `.font(.system(size:))` used on media overlays
    /// (stories, camera, calls) where the system font is intentional.
    /// For standard app typography prefer `DS.Font.*` (Instagram Sans).
    enum FontSize {
        /// 11pt — tiny overlay labels (sticker glyphs).
        static let overlayCaption: CGFloat = 11
        /// 12pt — small overlay labels.
        static let overlaySmall: CGFloat = 12
        /// 13pt — overlay body labels.
        static let overlayBody: CGFloat = 13
        /// 14pt — overlay emphasis labels.
        static let overlayEmphasis: CGFloat = 14
        /// 16pt — overlay icon/label.
        static let overlayMedium: CGFloat = 16
        /// 18pt — overlay control glyph.
        static let overlayLarge: CGFloat = 18
        /// 20pt — overlay action glyph (trash, more).
        static let overlayXLarge: CGFloat = 20
        /// 22pt — call control glyph.
        static let overlayCallGlyph: CGFloat = 22
    }

    // MARK: - Animation

    enum Animation {
        /// Quick micro-interaction (0.15s).
        static let fast: SwiftUI.Animation = .easeInOut(duration: 0.15)
        /// Standard transition (0.25s).
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.25)
        /// Smooth page transition (0.3s).
        static let smooth: SwiftUI.Animation = .easeInOut(duration: 0.3)
        /// Slow reveal (0.5s).
        static let slow: SwiftUI.Animation = .easeInOut(duration: 0.5)
        /// Spring bounce (like heart animation).
        static let spring: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.6)
        /// Gentle spring (sheet presentation).
        static let gentleSpring: SwiftUI.Animation = .spring(response: 0.4, dampingFraction: 0.8)
    }

    // MARK: - Duration (non-animation timings)

    enum Duration {
        /// Story item display (seconds).
        static let storyItem: TimeInterval = 5.0
        /// Story progress tick interval.
        static let storyTick: TimeInterval = 0.05
        /// Toast display duration.
        static let toast: TimeInterval = 2.5
        /// Call ring timeout.
        static let callRingTimeout: TimeInterval = 45.0
        /// WebSocket ping interval.
        static let wsPingInterval: TimeInterval = 25.0
        /// Network request timeout.
        static let networkTimeout: TimeInterval = 30.0
        /// Mock delay range (lower).
        static let mockDelayMin: TimeInterval = 0.3
        /// Mock delay range (upper).
        static let mockDelayMax: TimeInterval = 0.8
        /// Delay before auto-dismissing the action HUD after success/error feedback.
        static let hudDismiss: TimeInterval = 0.5
        /// Mock delay before a sent chat message transitions to "read" (receipt simulation).
        static let chatReadReceipt: TimeInterval = 1.5
    }

    // MARK: - Layout

    enum Layout {
        /// Number of columns in explore/profile grid.
        static let gridColumns: Int = 3
        /// Max number of media in a carousel post.
        static let maxPostMedia: Int = 10
        /// Max caption length.
        static let maxCaptionLength: Int = 2200
        /// Max bio length.
        static let maxBioLength: Int = 150
        /// Max comment length.
        static let maxCommentLength: Int = 2200
        /// Pagination default page size.
        static let defaultPageSize: Int = 20
        /// Messages page size.
        static let messagesPageSize: Int = 30
        /// Max leftward drag distance (pt) that fully reveals chat timestamps.
        static let chatTimestampRevealDistance: CGFloat = 80
        /// Min horizontal drag (pt) before the timestamp starts revealing.
        static let chatTimestampRevealThreshold: CGFloat = 5
        /// Story aspect ratio (9:16).
        static let storyAspectRatio: CGFloat = 9.0 / 16.0
        /// Post square aspect ratio.
        static let postSquareAspectRatio: CGFloat = 1.0
        /// Reels aspect ratio (9:16).
        static let reelsAspectRatio: CGFloat = 9.0 / 16.0
    }

    // MARK: - Stroke

    enum Stroke {
        /// Hairline border (0.5pt) — avatar rings, subtle outlines.
        static let hairline: CGFloat = 0.5
        /// Thin border (1pt).
        static let thin: CGFloat = 1
        /// Standard border (1.5pt).
        static let standard: CGFloat = 1.5
        /// Medium border (2pt) — story ring inactive.
        static let medium: CGFloat = 2
        /// Thick (3pt) — story ring active.
        static let thick: CGFloat = 3
        /// Extra thick (4pt) — capture button.
        static let extraThick: CGFloat = 4
    }

    // MARK: - Shadow

    enum Shadow {
        /// Standard blur radius for floating elements (toasts, cards).
        static let radius: CGFloat = 8
        /// Large blur radius (elevated media elements, call avatar).
        static let radiusLarge: CGFloat = 10
        /// Standard vertical offset for floating elements.
        static let offsetY: CGFloat = 4
    }
}
