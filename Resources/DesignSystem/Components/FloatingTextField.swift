//
//  FloatingTextField.swift
//  Instagram
//
//  A reusable text field with floating placeholder animation.
//  When focused or has text, the placeholder animates up and shrinks.
//

import SwiftUI
import UIKit

// MARK: - UIKit TextField Wrapper

/// A `UIViewRepresentable` wrapping `UITextField` to avoid the focus-loss issue
/// when toggling between SecureField/TextField in pure SwiftUI.
struct UIKitTextField: UIViewRepresentable {

    @Binding var text: String
    var isSecure: Bool
    var keyboardType: UIKeyboardType
    var textContentType: UITextContentType?
    @Binding var isFocused: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.font = .headlineRegular
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textChanged(_:)),
            for: .editingChanged
        )
        textField.tintColor = .textPrimary
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        // Update text only if it differs to avoid cursor jump
        if textField.text != text {
            textField.text = text
        }

        textField.isSecureTextEntry = isSecure
        textField.keyboardType = keyboardType
        textField.textContentType = textContentType

        // Manage focus
        if isFocused && !textField.isFirstResponder {
            // Delay to ensure view is in hierarchy
            DispatchQueue.main.async {
                textField.becomeFirstResponder()
            }
        } else if !isFocused && textField.isFirstResponder {
            DispatchQueue.main.async {
                textField.resignFirstResponder()
            }
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: UIKitTextField

        init(_ parent: UIKitTextField) {
            self.parent = parent
        }

        @objc func textChanged(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.isFocused = true
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.isFocused = false
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}

// MARK: - FloatingTextField

struct FloatingTextField: View {

    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?

    @State private var isFocused: Bool = false
    @State private var isPasswordVisible = false

    /// Whether the placeholder should float (field is focused or has content).
    private var isFloating: Bool {
        isFocused || !text.isEmpty
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Floating placeholder
            Text(placeholder)
                .font(isFloating ? DS.Font.caption : DS.Font.body)
                .foregroundStyle(ColorTokens.textTertiary)
                .offset(y: isFloating ? -12 : 0)
                .animation(.easeOut(duration: 0.15), value: isFloating)
                .allowsHitTesting(false)

            // Text input
            HStack(spacing: DS.Spacing.xs) {
                UIKitTextField(
                    text: $text,
                    isSecure: isSecure && !isPasswordVisible,
                    keyboardType: keyboardType,
                    textContentType: textContentType,
                    isFocused: $isFocused
                )
                .offset(y: isFloating ? 6 : 0)
                .animation(.easeOut(duration: 0.15), value: isFloating)

                if isSecure && isFocused {
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .font(.system(size: DS.Size.iconMedium))
                            .foregroundStyle(ColorTokens.textTertiary)
                            .frame(width: DS.Size.buttonSmallHeight, height: DS.Size.buttonSmallHeight)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .font(DS.Font.body)
        }
        .padding(.horizontal, DS.Spacing.md)
        .frame(height: DS.Size.textFieldHeight)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.input, style: .continuous)
                .fill(ColorTokens.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.input, style: .continuous)
                .stroke(
                    isFocused ? ColorTokens.textSecondary : ColorTokens.stroke,
                    lineWidth: DS.Stroke.thin
                )
        )
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Preview

#Preview("Empty - Unfocused") {
    VStack(spacing: 16) {
        FloatingTextField(
            placeholder: "Tên người dùng, email/số di động",
            text: .constant("")
        )
        FloatingTextField(
            placeholder: "Mật khẩu",
            text: .constant(""),
            isSecure: true
        )
    }
    .padding()
}

#Preview("With Text") {
    VStack(spacing: 16) {
        FloatingTextField(
            placeholder: "Tên người dùng, email/số di động",
            text: .constant("user@example.com")
        )
        FloatingTextField(
            placeholder: "Mật khẩu",
            text: .constant("password123"),
            isSecure: true
        )
    }
    .padding()
}
