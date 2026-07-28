//
//  LoginView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI

// MARK: - LoginView

struct LoginView: View {

    @State private var viewModel: AuthViewModel

    init(viewModel: AuthViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.xl) {
                    Spacer().frame(height: DS.Spacing.xxxl)

                    // MARK: Logo
                    logoSection

                    // MARK: Form
                    if viewModel.isLoginMode {
                        loginForm
                    } else {
                        registerForm
                    }

                    // MARK: Error
                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }

                    // MARK: Action Button
                    primaryButton

                    // MARK: Divider
                    dividerSection

                    // MARK: Toggle Mode
                    toggleModeSection

                    Spacer()
                }
                .padding(.horizontal, DS.Spacing.xxl)
            }
            .scrollDismissesKeyboard(.interactively)
            .disabled(viewModel.isLoading)
        }
    }

    // MARK: - Subviews

    private var logoSection: some View {
        VStack(spacing: DS.Spacing.xs) {
            Text("Instagram")
                .font(.system(size: 40, weight: .bold, design: .serif))

            Text(viewModel.isLoginMode ? "Sign in to continue" : "Create your account")
                .font(DS.Font.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, DS.Spacing.md)
    }

    private var loginForm: some View {
        VStack(spacing: DS.Spacing.formGap) {
            AuthTextField(
                placeholder: "Email",
                text: $viewModel.email,
                icon: "envelope",
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )

            AuthTextField(
                placeholder: "Password",
                text: $viewModel.password,
                icon: "lock",
                isSecure: true,
                textContentType: .password
            )
        }
    }

    private var registerForm: some View {
        VStack(spacing: DS.Spacing.formGap) {
            AuthTextField(
                placeholder: "Full Name",
                text: $viewModel.fullName,
                icon: "person",
                textContentType: .name
            )

            AuthTextField(
                placeholder: "Email",
                text: $viewModel.email,
                icon: "envelope",
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )

            AuthTextField(
                placeholder: "Phone Number",
                text: $viewModel.phone,
                icon: "phone",
                keyboardType: .phonePad,
                textContentType: .telephoneNumber
            )

            AuthTextField(
                placeholder: "Password",
                text: $viewModel.password,
                icon: "lock",
                isSecure: true,
                textContentType: .newPassword
            )

            AuthTextField(
                placeholder: "Confirm Password",
                text: $viewModel.confirmPassword,
                icon: "lock.shield",
                isSecure: true,
                textContentType: .newPassword
            )
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: DS.Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(ColorTokens.destructive)
            Text(message)
                .font(DS.Font.caption)
                .foregroundStyle(ColorTokens.destructive)
            Spacer()
        }
        .padding(DS.Spacing.sm)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: DS.Radius.medium))
    }

    private var primaryButton: some View {
        Button {
            Task {
                if viewModel.isLoginMode {
                    await viewModel.login()
                } else {
                    await viewModel.register()
                }
            }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(viewModel.isLoginMode ? "Log In" : "Sign Up")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: DS.Size.inputBarHeight)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.input, style: .continuous)
                    .fill(isFormValid ? ColorTokens.accentPrimary : ColorTokens.accentPrimary.opacity(DS.Opacity.overlay))
            )
        }
        .disabled(!isFormValid || viewModel.isLoading)
    }

    private var dividerSection: some View {
        HStack {
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 0.5)
            Text("OR")
                .font(DS.Font.caption)
                .foregroundStyle(.secondary)
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 0.5)
        }
    }

    private var toggleModeSection: some View {
        HStack(spacing: DS.Spacing.xxs) {
            Text(viewModel.isLoginMode ? "Don't have an account?" : "Already have an account?")
                .font(DS.Font.subheadline)
                .foregroundStyle(.secondary)
            Button(viewModel.isLoginMode ? "Sign Up" : "Log In") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.toggleMode()
                }
            }
            .font(DS.Font.subheadline)
            .fontWeight(.semibold)
        }
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        viewModel.isLoginMode ? viewModel.isLoginValid : viewModel.isRegisterValid
    }
}

// MARK: - AuthTextField

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String = ""
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?

    @State private var isPasswordVisible = false

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: DS.Spacing.lg)
            }

            if isSecure && !isPasswordVisible {
                SecureField(placeholder, text: $text)
                    .textContentType(textContentType)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            if isSecure {
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.formGap)
        .padding(.vertical, DS.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.input, style: .continuous)
                .fill(ColorTokens.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.input, style: .continuous)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}
