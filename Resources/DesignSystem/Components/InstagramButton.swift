//
//  InstagramButton.swift
//  Instagram
//
//  Created by Antigravity on 16/10/26.
//

import SwiftUI

// MARK: - InstagramButtonStyle

enum InstagramButtonStyle {
    /// Blue CTA button (brandBlue #0098FD), white text.
    case primary
    /// Adaptive secondary button (#EFEFEF Light / #262626 Dark), textPrimary.
    case secondary
    /// Red destructive action.
    case destructive
    /// Transparent with stroke border.
    case outline
    /// Borderless text button.
    case text
}

// MARK: - InstagramButtonSize

enum InstagramButtonSize {
    case small    // 30pt height
    case compact  // 36pt height
    case standard // 44pt height
    case large    // 50pt height

    var height: CGFloat {
        switch self {
        case .small: return DS.Size.buttonSmallHeight
        case .compact: return DS.Size.buttonCompactHeight
        case .standard: return DS.Size.buttonDefaultHeight
        case .large: return DS.Size.buttonLargeHeight
        }
    }

    var font: Font {
        switch self {
        case .small: return DS.Font.captionBold
        case .compact: return DS.Font.subheadlineBold
        case .standard: return DS.Font.subheadlineBold
        case .large: return DS.Font.headline
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return DS.Spacing.sm
        case .compact: return DS.Spacing.md
        case .standard: return DS.Spacing.md
        case .large: return DS.Spacing.lg
        }
    }
}

// MARK: - InstagramButton

struct InstagramButton: View {

    let title: String
    var icon: String? = nil
    var style: InstagramButtonStyle = .primary
    var size: InstagramButtonSize = .standard
    var isLoading: Bool = false
    var isFullWidth: Bool = true
    var isEnabled: Bool = true
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        style: InstagramButtonStyle = .primary,
        size: InstagramButtonSize = .standard,
        isLoading: Bool = false,
        isFullWidth: Bool = true,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isFullWidth = isFullWidth
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button {
            guard !isLoading && isEnabled else { return }
            HapticFeedbackSafe.impact(.light)
            action()
        } label: {
            HStack(spacing: DS.Spacing.iconGap) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.85)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(size.font)
                    }
                    Text(title)
                        .font(size.font)
                }
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, isFullWidth ? 0 : size.horizontalPadding)
            .foregroundStyle(foregroundColor)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
            .overlay(strokeOverlay)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.5)
    }

    // MARK: - Colors & Backgrounds

    private var foregroundColor: Color {
        guard isEnabled else { return ColorTokens.textTertiary }
        switch style {
        case .primary:
            return .white
        case .secondary:
            return ColorTokens.textPrimary
        case .destructive:
            return .white
        case .outline:
            return ColorTokens.textPrimary
        case .text:
            return ColorTokens.brandBlue
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            ColorTokens.buttonPrimary
        case .secondary:
            ColorTokens.buttonSecondary
        case .destructive:
            ColorTokens.destructive
        case .outline, .text:
            Color.clear
        }
    }

    @ViewBuilder
    private var strokeOverlay: some View {
        if style == .outline {
            RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                .stroke(ColorTokens.stroke, lineWidth: DS.Stroke.thin)
        }
    }
}
