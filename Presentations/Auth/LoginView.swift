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
            VStack(spacing: 0) {
                Spacer()

                // MARK: Logo
                instagramLogo
                    .padding(.bottom, DS.Spacing.xxxl)

                // MARK: Form
                if viewModel.isLoginMode {
                    loginForm
                } else {
                    registerForm
                }

                // MARK: Error
                if let error = viewModel.errorMessage {
                    errorBanner(error)
                        .padding(.top, DS.Spacing.sm)
                }

                // MARK: Login Button
                primaryButton
                    .padding(.top, DS.Spacing.lg)

                // MARK: Forgot Password
                if viewModel.isLoginMode {
                    Button {
                        // TODO: Forgot password action
                    } label: {
                        Text(L10n.Auth.forgotPassword)
                            .font(DS.Font.headline)
                            .foregroundStyle(ColorTokens.textPrimary)
                    }
                    .padding(.top, DS.Spacing.lg)
                }

                Spacer()
                Spacer()

                // MARK: Bottom Section
                bottomSection
            }
            .padding(.horizontal, DS.Padding.horizontal)
            .disabled(viewModel.isLoading)
            .dismissKeyboardOnTap()
            .background(.backgroundSecondary)
        }
    }

    // MARK: - Subviews

    private var instagramLogo: some View {
        Image(.splashIcon)
            .resizable()
            .scaledToFit()
            .frame(width: 60, height: 60)
    }

    private var loginForm: some View {
        VStack(spacing: DS.Spacing.sm) {
            FloatingTextField(
                placeholder: L10n.Auth.Placeholder.usernameOrEmail,
                text: $viewModel.email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )

            FloatingTextField(
                placeholder: L10n.Auth.Placeholder.password,
                text: $viewModel.password,
                isSecure: true,
                textContentType: .password
            )
        }
    }

    private var registerForm: some View {
        VStack(spacing: DS.Spacing.sm) {
            FloatingTextField(
                placeholder: L10n.Auth.Placeholder.fullName,
                text: $viewModel.fullName,
                textContentType: .name
            )

            FloatingTextField(
                placeholder: L10n.Auth.Placeholder.email,
                text: $viewModel.email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )

            FloatingTextField(
                placeholder: L10n.Auth.Placeholder.phone,
                text: $viewModel.phone,
                keyboardType: .phonePad,
                textContentType: .telephoneNumber
            )

            FloatingTextField(
                placeholder: L10n.Auth.Placeholder.password,
                text: $viewModel.password,
                isSecure: true,
                textContentType: .newPassword
            )

            FloatingTextField(
                placeholder: L10n.Auth.Placeholder.confirmPassword,
                text: $viewModel.confirmPassword,
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
                    Text(viewModel.isLoginMode ? L10n.Auth.login : L10n.Auth.register)
                        .font(DS.Font.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: DS.Size.buttonDefaultHeight)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.pill, style: .continuous)
                    .fill(isFormValid ? ColorTokens.accentPrimary : ColorTokens.accentPrimary.opacity(DS.Opacity.medium))
            )
        }
        .disabled(!isFormValid || viewModel.isLoading)
    }

    private var bottomSection: some View {
        VStack(spacing: DS.Spacing.md) {
            // Create account / Toggle mode button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.toggleMode()
                }
            } label: {
                Text(viewModel.isLoginMode ? L10n.Auth.createAccount : L10n.Auth.haveAccount)
                    .font(DS.Font.headline)
                    .foregroundStyle(ColorTokens.accentPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: DS.Size.buttonDefaultHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.pill, style: .continuous)
                            .stroke(ColorTokens.accentPrimary, lineWidth: DS.Stroke.thin)
                    )
            }

            // Meta logo
            HStack(spacing: DS.Spacing.xxs) {
                Image(systemName: "infinity")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ColorTokens.textPrimary)
                Text("Meta")
                    .font(DS.Font.headline)
                    .foregroundStyle(ColorTokens.textPrimary)
            }
            .padding(.bottom, DS.Spacing.md)
        }
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        viewModel.isLoginMode ? viewModel.isLoginValid : viewModel.isRegisterValid
    }
}
