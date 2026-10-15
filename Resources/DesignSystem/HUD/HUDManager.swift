//
//  HUDManager.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import ProgressHUD

// MARK: - HUDStyle

enum HUDStyle {
    case loading(String? = nil)
    case success(String? = nil)
    case error(String? = nil)
    case progress(CGFloat)
    case symbol(String, String? = nil)
}

// MARK: - HUDManager

/// Unified loading / feedback indicator wrapping ProgressHUD.
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
/// Example:
/// ```swift
/// await HUDManager.shared.performWithLoading {
///     try await createPostUseCase.execute(input)
/// } onSuccess: { _ in
///     AppRouter.shared.dismiss()
/// }
/// ```
///
/// Call from any `@MainActor` context (ViewModels, Views, etc.).
@MainActor
final class HUDManager {

    static let shared = HUDManager()

    private init() {
        configureAppearance()
    }

    // MARK: - Configuration

    private func configureAppearance() {
        ProgressHUD.animationType = .circleStrokeSpin
        ProgressHUD.colorHUD = ColorTokens.textSecondary
        ProgressHUD.colorBackground = ColorTokens.overlayDark.opacity(DS.Opacity.hudBackground)
        ProgressHUD.colorAnimation = ColorTokens.accentPrimary
        ProgressHUD.colorStatus = ColorTokens.textPrimary
        ProgressHUD.fontStatus = DS.Font.bodyBold
    }

    // MARK: - Show

    func show(_ style: HUDStyle = .loading()) {
        switch style {
        case .loading(let message):
            if let message {
                ProgressHUD.animate(message)
            } else {
                ProgressHUD.animate()
            }

        case .success(let message):
            ProgressHUD.succeed(message ?? L10n.HUD.success)

        case .error(let message):
            ProgressHUD.failed(message ?? L10n.HUD.error)

        case .progress(let value):
            ProgressHUD.progress(value)

        case .symbol(let systemName, let message):
            if let message {
                ProgressHUD.symbol(message, name: systemName)
            } else {
                ProgressHUD.symbol(name: systemName)
            }
        }
    }

    /// Show loading with a status message.
    func showLoading(_ message: String? = nil) {
        show(.loading(message))
    }

    /// Show success feedback.
    func showSuccess(_ message: String? = nil) {
        show(.success(message))
    }

    /// Show error feedback.
    func showError(_ message: String? = nil) {
        show(.error(message))
    }

    /// Show informational feedback with an info icon.
    func showInfo(_ message: String? = nil) {
        show(.symbol("info.circle", message))
    }

    /// Update progress (0.0 – 1.0).
    func showProgress(_ value: CGFloat) {
        show(.progress(value))
    }

    /// Dismiss any visible HUD immediately.
    func dismiss() {
        ProgressHUD.dismiss()
    }

    /// Remove HUD after the standard dismiss delay.
    func dismissAfter() {
        dismissAfter(DS.Duration.hudDismiss)
    }

    /// Remove HUD after a specific delay.
    func dismissAfter(_ delay: TimeInterval) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            ProgressHUD.dismiss()
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

// MARK: - View Extension

extension View {
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
