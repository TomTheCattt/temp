//
//  ToastManager.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import PopupView

// MARK: - ToastStyle

enum ToastStyle {
    case success
    case error
    case warning
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error:   return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info:    return "info.circle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .success: return ColorTokens.success
        case .error:   return ColorTokens.destructive
        case .warning: return ColorTokens.warning
        case .info:    return ColorTokens.accentPrimary
        }
    }

    var backgroundColor: Color {
        tintColor.opacity(DS.Opacity.subtle)
    }
}

// MARK: - ToastItem

struct ToastItem: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let style: ToastStyle
    let duration: TimeInterval

    init(message: String, style: ToastStyle, duration: TimeInterval = DS.Duration.toast) {
        self.message = message
        self.style = style
        self.duration = duration
    }

    static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - ToastManager

@MainActor
@Observable
final class ToastManager {

    static let shared = ToastManager()

    var currentToast: ToastItem?

    private init() {}

    // MARK: - Public API

    func show(_ message: String, style: ToastStyle = .info, duration: TimeInterval = DS.Duration.toast) {
        currentToast = ToastItem(message: message, style: style, duration: duration)
    }

    func success(_ message: String, duration: TimeInterval = DS.Duration.toast) {
        show(message, style: .success, duration: duration)
    }

    func error(_ message: String, duration: TimeInterval = DS.Duration.toast) {
        show(message, style: .error, duration: duration)
    }

    func warning(_ message: String, duration: TimeInterval = DS.Duration.toast) {
        show(message, style: .warning, duration: duration)
    }

    func info(_ message: String, duration: TimeInterval = DS.Duration.toast) {
        show(message, style: .info, duration: duration)
    }

    func dismiss() {
        currentToast = nil
    }
}

// MARK: - Toast View

private struct ToastContentView: View {
    let item: ToastItem

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            InstagramIcon(.system(name: item.style.icon), size: DS.Size.iconMedium, color: item.style.tintColor)

            Text(item.message)
                .font(DS.Font.subheadline)
                .foregroundStyle(ColorTokens.textPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.formGap)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .fill(ColorTokens.backgroundElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                        .fill(item.style.backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                        .stroke(item.style.tintColor.opacity(DS.Opacity.divider), lineWidth: DS.Stroke.thin)
                )
        )
        .shadow(color: ColorTokens.shadowMedium, radius: DS.Shadow.radius, x: 0, y: DS.Shadow.offsetY)
        .padding(.horizontal, DS.Spacing.lg)
    }
}

// MARK: - View Modifier

/// Attach this modifier once at the root view to enable global toast display.
struct ToastModifier: ViewModifier {
    @State private var toastManager = ToastManager.shared

    func body(content: Content) -> some View {
        content
            .popup(item: $toastManager.currentToast) { item in
                ToastContentView(item: item)
            } customize: {
                $0
                    .type(.floater())
                    .position(.top)
                    .animation(DS.Animation.gentleSpring)
                    .autohideIn(toastManager.currentToast?.duration ?? DS.Duration.toast)
                    .dismissCallback {
                        toastManager.dismiss()
                    }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Enables global toast notifications on this view hierarchy.
    /// Typically applied once at the root (e.g. ContentView).
    func withToast() -> some View {
        modifier(ToastModifier())
    }
}
