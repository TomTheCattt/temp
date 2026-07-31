//
//  BaseViewModifier.swift
//  Instagram
//
//  Base features applied globally: tap to dismiss keyboard + edge swipe to pop.
//

import SwiftUI

// MARK: - Edge Swipe to Pop (interactive pop gesture)

/// Ensures the interactive pop gesture (edge swipe from left) stays enabled
/// even when custom navigation bar back buttons are used.
struct EdgeSwipePopModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(InteractivePopGestureEnabler())
    }
}

/// UIViewControllerRepresentable that keeps the interactivePopGestureRecognizer enabled.
private struct InteractivePopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = InteractivePopController()
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private final class InteractivePopController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        enableInteractivePopGesture()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        enableInteractivePopGesture()
    }

    private func enableInteractivePopGesture() {
        guard let navigationController = self.navigationController else { return }
        navigationController.interactivePopGestureRecognizer?.isEnabled = true
        navigationController.interactivePopGestureRecognizer?.delegate = nil
    }
}

// MARK: - Combined Base Modifier

/// Combines base behaviors into one modifier.
/// Currently: edge swipe pop only. Keyboard dismiss is handled per-screen.
struct BaseViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .modifier(EdgeSwipePopModifier())
    }
}

// MARK: - View Extension

extension View {
    /// Apply base features globally: edge swipe to pop.
    /// Applied at the root level (e.g., `InstagramApp`).
    func withBaseFeatures() -> some View {
        modifier(BaseViewModifier())
    }

    /// Dismiss keyboard when tapping outside text fields.
    /// Apply on screens with text input (e.g., Login, Search, Chat).
    ///
    /// Usage:
    /// ```swift
    /// VStack { ... }
    ///     .dismissKeyboardOnTap()
    /// ```
    func dismissKeyboardOnTap() -> some View {
        self
            .contentShape(Rectangle())
            .onTapGesture {
                KeyboardHelper.dismiss()
            }
    }

    /// Disable interactive pop gesture on specific views (e.g., payment flow, onboarding).
    func disableInteractivePop() -> some View {
        self.background(InteractivePopDisabler())
    }
}

/// Disables interactive pop gesture for specific screens.
private struct InteractivePopDisabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = DisablePopController()
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private final class DisablePopController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Re-enable when leaving this screen
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
}

// MARK: - Global Keyboard Dismiss Helper

/// Call from anywhere to dismiss keyboard programmatically.
///
/// Usage:
/// ```swift
/// KeyboardHelper.dismiss()
/// ```
enum KeyboardHelper {
    static func dismiss() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}
