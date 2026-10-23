//
//  HUDManager.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI

// MARK: - HUDStyle

enum HUDStyle: Equatable {
    case loading(String? = nil)
    case success(String? = nil)
    case error(String? = nil)
    case progress(CGFloat, String? = nil)
    case symbol(String, String? = nil)
}

// MARK: - HUDManager

/// Unified loading / feedback indicator implemented in pure SwiftUI.
///
/// Use this for **blocking, one-shot ACTIONS** — never for background data fetches
/// (those show skeletons/shimmers instead). The HUD dims the screen, shows a spinner
/// while the action runs, then flashes success/error feedback and auto-dismisses.
///
/// Intended action call-sites (invoke `performWithLoading` from these `@MainActor` view-models):
/// - Create post (publish)
/// - Create reel (publish)
/// - Edit profile — save
/// - Change password
/// - Send message
/// - Follow / unfollow
/// - Any other user-initiated, blocking mutation
///
/// Call from any `@MainActor` context (ViewModels, Views, etc.).
@MainActor
@Observable
final class HUDManager {

    static let shared = HUDManager()

    private(set) var currentStyle: HUDStyle?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    // MARK: - Show

    func show(_ style: HUDStyle = .loading()) {
        dismissTask?.cancel()
        currentStyle = style

        switch style {
        case .success:
            HapticFeedbackSafe.notification(.success)
            dismissAfter(DS.Duration.hudDismiss + 0.6)
        case .error:
            HapticFeedbackSafe.notification(.error)
            dismissAfter(DS.Duration.hudDismiss + 0.9)
        case .symbol:
            HapticFeedbackSafe.impact(.medium)
            dismissAfter(DS.Duration.hudDismiss + 0.6)
        case .loading, .progress:
            break
        }
    }

    /// Show loading with a status message.
    func showLoading(_ message: String? = nil) {
        show(.loading(message))
    }

    /// Show success feedback.
    func showSuccess(_ message: String? = nil) {
        show(.success(message ?? L10n.HUD.success))
    }

    /// Show error feedback.
    func showError(_ message: String? = nil) {
        show(.error(message ?? L10n.HUD.error))
    }

    /// Show informational feedback with an info icon.
    func showInfo(_ message: String? = nil) {
        show(.symbol("info.circle", message))
    }

    /// Update progress (0.0 – 1.0).
    func showProgress(_ value: CGFloat, message: String? = nil) {
        show(.progress(value, message))
    }

    /// Dismiss any visible HUD immediately.
    func dismiss() {
        dismissTask?.cancel()
        withAnimation(DS.Animation.gentleSpring) {
            currentStyle = nil
        }
    }

    /// Remove HUD after the standard dismiss delay.
    func dismissAfter() {
        dismissAfter(DS.Duration.hudDismiss)
    }

    /// Remove HUD after a specific delay.
    func dismissAfter(_ delay: TimeInterval) {
        dismissTask?.cancel()
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            if !Task.isCancelled {
                withAnimation(DS.Animation.gentleSpring) {
                    self.currentStyle = nil
                }
            }
        }
    }

    // MARK: - Convenience async wrapper

    /// Execute an async task while showing HUD. Auto-dismisses on completion.
    func performWithLoading<T>(
        message: String? = nil,
        task: @escaping () async throws -> T,
        onSuccess: ((T) -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) async {
        showLoading(message)
        do {
            let result = try await task()
            showSuccess()
            onSuccess?(result)
        } catch {
            // Always surface a friendly, curated message — never raw localizedDescription.
            showError(error.userMessage)
            onError?(error)
        }
    }
}

// MARK: - InstagramHUDCardView

private struct InstagramHUDCardView: View {
    let style: HUDStyle

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            indicatorView
                .frame(width: 44, height: 44)

            if let message = statusMessage, !message.isEmpty {
                Text(message)
                    .font(DS.Font.subheadlineBold)
                    .foregroundColor(ColorTokens.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.vertical, DS.Spacing.lg)
        .frame(minWidth: 120, minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                        .fill(ColorTokens.backgroundElevated.opacity(0.85))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                        .stroke(ColorTokens.stroke.opacity(DS.Opacity.divider), lineWidth: DS.Stroke.thin)
                )
        )
        .shadow(color: ColorTokens.shadowMedium, radius: DS.Shadow.radius, x: 0, y: DS.Shadow.offsetY)
    }

    private var statusMessage: String? {
        switch style {
        case .loading(let message): return message
        case .success(let message): return message
        case .error(let message): return message
        case .progress(_, let message): return message
        case .symbol(_, let message): return message
        }
    }

    @ViewBuilder
    private var indicatorView: some View {
        switch style {
        case .loading:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: ColorTokens.accentPrimary))
                .scaleEffect(1.2)

        case .success:
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(ColorTokens.success)
                .transition(.scale.combined(with: .opacity))

        case .error:
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(ColorTokens.destructive)
                .transition(.scale.combined(with: .opacity))

        case .progress(let value, _):
            ProgressView(value: Double(value), total: 1.0)
                .progressViewStyle(CircularProgressViewStyle(tint: ColorTokens.accentPrimary))
                .scaleEffect(1.2)

        case .symbol(let systemName, _):
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .foregroundColor(ColorTokens.textPrimary)
        }
    }
}

// MARK: - HUDModifier

struct HUDModifier: ViewModifier {
    @State private var hudManager = HUDManager.shared

    func body(content: Content) -> some View {
        content
            .overlay {
                if let style = hudManager.currentStyle {
                    ZStack {
                        ColorTokens.overlayDark
                            .opacity(DS.Opacity.hudBackground)
                            .ignoresSafeArea()
                            .transition(.opacity)

                        InstagramHUDCardView(style: style)
                            .transition(.scale(scale: 0.85).combined(with: .opacity))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(9999)
                    .allowsHitTesting(true)
                }
            }
            .animation(DS.Animation.gentleSpring, value: hudManager.currentStyle)
    }
}

// MARK: - View Extension

extension View {
    /// Enables global action HUD display on this view hierarchy.
    /// Typically applied once at the root (InstagramApp).
    func withHUD() -> some View {
        modifier(HUDModifier())
    }

    /// Show loading HUD tied to a binding.
    func hud(isLoading: Binding<Bool>, message: String? = nil) -> some View {
        onChange(of: isLoading.wrappedValue) { _, newValue in
            if newValue {
                HUDManager.shared.showLoading(message)
            } else {
                HUDManager.shared.dismiss()
            }
        }
    }
}
