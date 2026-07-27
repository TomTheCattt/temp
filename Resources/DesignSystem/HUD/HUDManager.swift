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
    case loading
    case success(String? = nil)
    case error(String? = nil)
    case progress(CGFloat)
    case image(String, String?) // systemName, message

    /// Banner style — shows a brief top-of-screen notification then auto-hides.
    case banner(String, String?, BannerStyle)
}

// MARK: - BannerStyle

enum BannerStyle {
    case success
    case error
    case info
}

// MARK: - HUDManager

/// Unified loading / feedback indicator wrapping ProgressHUD.
/// Call from any `@MainActor` context (ViewModels, Views, etc.)
@MainActor
final class HUDManager {

    static let shared = HUDManager()

    private init() {
        configureAppearance()
    }

    // MARK: - Configuration

    private func configureAppearance() {
        ProgressHUD.animationType = .circleStrokeSpin
        ProgressHUD.colorHUD = .systemGray6
        ProgressHUD.colorBackground = .black.withAlphaComponent(0.3)
        ProgressHUD.colorAnimation = .systemBlue
        ProgressHUD.colorStatus = .label
        ProgressHUD.fontStatus = .systemFont(ofSize: 15, weight: .medium)
        ProgressHUD.mediaSize = 100
    }

    // MARK: - Show

    func show(_ style: HUDStyle = .loading) {
        switch style {
        case .loading:
            ProgressHUD.animate()

        case .success(let message):
            if let message {
                ProgressHUD.succeed(message, delay: 1.5)
            } else {
                ProgressHUD.succeed(delay: 1.5)
            }

        case .error(let message):
            if let message {
                ProgressHUD.failed(message, delay: 2.0)
            } else {
                ProgressHUD.failed(delay: 2.0)
            }

        case .progress(let value):
            ProgressHUD.progress(value)

        case .image(let systemName, let message):
            ProgressHUD.symbol(systemName)
            if let message {
                ProgressHUD.succeed(message, delay: 1.5)
            }

        case .banner(let title, let message, let bannerStyle):
            showBanner(title: title, message: message, style: bannerStyle)
        }
    }

    /// Show loading with a status message.
    func showLoading(_ message: String? = nil) {
        if let message {
            ProgressHUD.animate(message)
        } else {
            ProgressHUD.animate()
        }
    }

    /// Show success feedback.
    func showSuccess(_ message: String? = nil, delay: TimeInterval = 1.5) {
        if let message {
            ProgressHUD.succeed(message, delay: delay)
        } else {
            ProgressHUD.succeed(delay: delay)
        }
    }

    /// Show error feedback.
    func showError(_ message: String? = nil, delay: TimeInterval = 2.0) {
        if let message {
            ProgressHUD.failed(message, delay: delay)
        } else {
            ProgressHUD.failed(delay: delay)
        }
    }

    /// Update progress (0.0 – 1.0).
    func showProgress(_ value: CGFloat) {
        ProgressHUD.progress(value)
    }

    /// Dismiss any visible HUD immediately.
    func dismiss() {
        ProgressHUD.dismiss()
    }

    /// Remove HUD after a short delay.
    func dismissAfter(_ delay: TimeInterval = 0.5) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
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
            showError(error.localizedDescription)
            onError?(error)
        }
    }

    // MARK: - Private

    private func showBanner(title: String, message: String?, style: BannerStyle) {
        let symbol: String
        switch style {
        case .success: symbol = "checkmark.circle.fill"
        case .error:   symbol = "xmark.circle.fill"
        case .info:    symbol = "info.circle.fill"
        }
        ProgressHUD.symbol(symbol)
        ProgressHUD.succeed(message ?? title, delay: 2.0)
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
