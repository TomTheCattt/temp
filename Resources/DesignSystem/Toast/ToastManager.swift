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
        case .success: return .green
        case .error:   return .red
        case .warning: return .orange
        case .info:    return .blue
        }
    }

    var backgroundColor: Color {
        switch self {
        case .success: return Color.green.opacity(0.12)
        case .error:   return Color.red.opacity(0.12)
        case .warning: return Color.orange.opacity(0.12)
        case .info:    return Color.blue.opacity(0.12)
        }
    }
}

// MARK: - ToastItem

struct ToastItem: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let style: ToastStyle
    let duration: TimeInterval

    init(message: String, style: ToastStyle, duration: TimeInterval = 3.0) {
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

    private(set) var currentToast: ToastItem?

    private init() {}

    // MARK: - Public API

    func show(_ message: String, style: ToastStyle = .info, duration: TimeInterval = 3.0) {
        currentToast = ToastItem(message: message, style: style, duration: duration)
    }

    func success(_ message: String, duration: TimeInterval = 3.0) {
        show(message, style: .success, duration: duration)
    }

    func error(_ message: String, duration: TimeInterval = 3.0) {
        show(message, style: .error, duration: duration)
    }

    func warning(_ message: String, duration: TimeInterval = 3.0) {
        show(message, style: .warning, duration: duration)
    }

    func info(_ message: String, duration: TimeInterval = 3.0) {
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
        HStack(spacing: 12) {
            Image(systemName: item.style.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(item.style.tintColor)

            Text(item.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(item.style.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(item.style.tintColor.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
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
                    .animation(.spring(response: 0.4, dampingFraction: 0.8))
                    .autohideIn(toastManager.currentToast?.duration ?? 3.0)
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
