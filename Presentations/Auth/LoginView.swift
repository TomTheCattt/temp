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
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)

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
                .padding(.horizontal, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .disabled(viewModel.isLoading)
        }
    }

    // MARK: - Subviews

    private var logoSection: some View {
        VStack(spacing: 8) {
            Text("Instagram")
                .font(.system(size: 40, weight: .bold, design: .serif))

            Text(viewModel.isLoginMode ? "Sign in to continue" : "Create your account")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 16)
    }

    private var loginForm: some View {
        VStack(spacing: 14) {
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
        VStack(spacing: 14) {
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
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
            Spacer()
        }
        .padding(12)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
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
            .frame(height: 48)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isFormValid ? Color.blue : Color.blue.opacity(0.5))
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
                .font(.caption)
                .foregroundStyle(.secondary)
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 0.5)
        }
    }

    private var toggleModeSection: some View {
        HStack(spacing: 4) {
            Text(viewModel.isLoginMode ? "Don't have an account?" : "Already have an account?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button(viewModel.isLoginMode ? "Sign Up" : "Log In") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.toggleMode()
                }
            }
            .font(.subheadline)
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
        HStack(spacing: 12) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
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
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}
