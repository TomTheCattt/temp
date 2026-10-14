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
/// Includes edge swipe pop and global tap-outside to dismiss keyboard.
struct BaseViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .modifier(EdgeSwipePopModifier())
            .modifier(GlobalKeyboardDismissModifier())
    }
}

// MARK: - Global Tap to Dismiss Keyboard

/// Attaches a non-cancelling tap gesture to the window to dismiss the keyboard
/// whenever the user taps outside text inputs.
struct GlobalKeyboardDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(KeyboardDismissGestureEnabler())
    }
}

/// A transparent UIViewRepresentable that attaches the window-level tap recognizer.
private struct KeyboardDismissGestureEnabler: UIViewRepresentable {
    func makeUIView(context: Context) -> KeyboardDismissHelperView {
        KeyboardDismissHelperView()
    }

    func updateUIView(_ uiView: KeyboardDismissHelperView, context: Context) {}
}

private final class KeyboardDismissHelperView: UIView, UIGestureRecognizerDelegate {

    private var isKeyboardVisible = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        setupKeyboardObservers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isHidden = true
        setupKeyboardObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow() {
        isKeyboardVisible = true
    }

    @objc private func keyboardWillHide() {
        isKeyboardVisible = false
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = self.window else { return }

        // Attach only once per window
        if window.gestureRecognizers?.contains(where: { $0 is GlobalKeyboardDismissGestureRecognizer }) != true {
            let tap = GlobalKeyboardDismissGestureRecognizer(target: self, action: #selector(handleTap))
            tap.cancelsTouchesInView = false
            tap.delegate = self
            window.addGestureRecognizer(tap)
        }
    }

    @objc private func handleTap() {
        KeyboardHelper.dismiss()
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only active when the keyboard is actually visible on screen
        guard isKeyboardVisible else { return false }

        // If the tap was inside an active text input, do not dismiss keyboard (allows cursor moves & field focus)
        var current: UIView? = touch.view
        while let view = current {
            if view is UITextField || view is UITextView {
                return false
            }
            current = view.superview
        }

        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Never block other gestures (scrolls, pans, taps, long presses)
        return true
    }
}

private final class GlobalKeyboardDismissGestureRecognizer: UITapGestureRecognizer {}

// MARK: - View Extension

extension View {
    /// Apply base features globally: edge swipe to pop and global tap to dismiss keyboard.
    /// Applied at the root level (e.g., `InstagramApp`).
    func withBaseFeatures() -> some View {
        modifier(BaseViewModifier())
    }

    /// Dismiss keyboard when tapping outside text fields on this view.
    ///
    /// Usage:
    /// ```swift
    /// VStack { ... }
    ///     .dismissKeyboardOnTap()
    /// ```
    func dismissKeyboardOnTap() -> some View {
        self.background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    KeyboardHelper.dismiss()
                }
        )
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
