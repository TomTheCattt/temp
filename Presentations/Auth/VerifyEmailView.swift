//
//  VerifyEmailView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI

// MARK: - VerifyEmailView

struct VerifyEmailView: View {

    @State private var viewModel: VerifyEmailViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        viewModel: VerifyEmailViewModel,
        onSuccess: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onSuccess = onSuccess
    }

    private let onSuccess: (() -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                // MARK: Icon
                ZStack {
                    Circle()
                        .fill(ColorTokens.accentPrimary.opacity(0.15))
                        .frame(width: 100, height: 100)

                    InstagramIcon(.system(name: "envelope.badge"), size: 44, color: ColorTokens.accentPrimary)
                }
                .padding(.bottom, DS.Spacing.xxxl)

                // MARK: Title & Description
                VStack(spacing: DS.Spacing.sm) {
                    Text(L10n.VerifyEmail.title)
                        .font(DS.Font.title2)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(L10n.VerifyEmail.description)
                        .font(DS.Font.body)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Padding.horizontal)
                }
                .padding(.bottom, DS.Spacing.xl)

                // MARK: OTP Input (6 digits)
                if viewModel.requiresOTP {
                    otpInputView
                        .padding(.horizontal, DS.Padding.horizontal)
                        .padding(.bottom, DS.Spacing.lg)
                }

                // MARK: Form (for manual token entry)
                if !viewModel.requiresOTP {
                    VStack(spacing: DS.Spacing.md) {
                        FloatingTextField(
                            placeholder: L10n.VerifyEmail.tokenPlaceholder,
                            text: $viewModel.token,
                            keyboardType: .default,
                            textContentType: .oneTimeCode
                        )
                        .errorShake(trigger: viewModel.errorMessage)

                        if let error = viewModel.errorMessage {
                            HStack(spacing: DS.Spacing.xs) {
                                InstagramIcon(.system(name: "exclamationmark.triangle.fill"), size: DS.Size.iconSmall, color: ColorTokens.destructive)
                                Text(error)
                                    .font(DS.Font.caption)
                                    .foregroundStyle(ColorTokens.destructive)
                                Spacer()
                            }
                            .padding(DS.Spacing.sm)
                            .background(ColorTokens.destructive.opacity(DS.Opacity.faint), in: RoundedRectangle(cornerRadius: DS.Radius.medium))
                            .transition(AppTransition.moveIn(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, DS.Padding.horizontal)
                }

                // MARK: Verify Button
                Button {
                    Task {
                        await viewModel.verifyEmail()
                        if viewModel.isVerified {
                            onSuccess?()
                        }
                    }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(viewModel.requiresOTP ? L10n.VerifyEmail.verifyButton : L10n.VerifyEmail.submitButton)
                                .font(DS.Font.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: DS.Size.buttonDefaultHeight)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.pill, style: .continuous)
                            .fill(viewModel.isFormValid ? ColorTokens.accentPrimary : ColorTokens.accentPrimary.opacity(DS.Opacity.medium))
                    )
                }
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
                .padding(.horizontal, DS.Padding.horizontal)
                .padding(.top, DS.Spacing.md)

                // MARK: Resend Email
                VStack(spacing: DS.Spacing.xs) {
                    Text(L10n.VerifyEmail.didNotReceive)
                        .font(DS.Font.caption)
                        .foregroundStyle(ColorTokens.textSecondary)

                    Button {
                        Task {
                            await viewModel.resendVerification()
                        }
                    } label: {
                        HStack(spacing: DS.Spacing.xxs) {
                            if viewModel.isResending {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 14, height: 14)
                            }
                            Text(viewModel.resendCountdown > 0 ? "\(viewModel.resendCountdown)s" : L10n.VerifyEmail.resendButton)
                                .font(DS.Font.captionBold)
                                .foregroundStyle(ColorTokens.accentPrimary)
                        }
                    }
                    .disabled(viewModel.isResending || viewModel.resendCountdown > 0)
                }
                .padding(.top, DS.Spacing.lg)

                Spacer()
                Spacer()

                // MARK: Back to Login
                Button {
                    dismiss()
                } label: {
                    Text(L10n.VerifyEmail.backToLogin)
                        .font(DS.Font.headline)
                        .foregroundStyle(ColorTokens.accentPrimary)
                }
                .padding(.bottom, DS.Spacing.md)
            }
            .navigationTitle(L10n.VerifyEmail.navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) {
                        dismiss()
                    }
                    .foregroundStyle(ColorTokens.accentPrimary)
                }
            }
            .background(.backgroundSecondary)
            .dismissKeyboardOnTap()
            .alert(L10n.VerifyEmail.successTitle, isPresented: $viewModel.showSuccessAlert) {
                Button(L10n.Common.ok) {
                    dismiss()
                }
            } message: {
                Text(L10n.VerifyEmail.successMessage)
            }
            .onDisappear {
                viewModel.cancelResendCountdown()
            }
        }
    }

    // MARK: - OTP Input View
    private var otpInputView: some View {
        HStack(spacing: DS.Spacing.xs) {
            ForEach(0..<6, id: \.self) { index in
                OTPDigitView(
                    text: otpBinding(for: index),
                    isFocused: viewModel.focusedIndex == index,
                    isError: otpError(for: index)
                )
                .onTapGesture {
                    viewModel.focusedIndex = index
                }
            }
        }
    }

    // Helper bindings to simplify type-checking
    private func otpBinding(for index: Int) -> Binding<String> {
        Binding(
            get: { index < viewModel.otpDigits.count ? String(viewModel.otpDigits[index]) : "" },
            set: { viewModel.updateOTPDigit(at: index, with: $0) }
        )
    }

    private func otpError(for index: Int) -> Bool {
        viewModel.showError && index < viewModel.otpDigits.count && viewModel.otpDigits[index] == " "
    }
}

// MARK: - OTP Digit View
private struct OTPDigitView: View {
    @Binding var text: String
    let isFocused: Bool
    let isError: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.Radius.medium)
                .stroke(
                    isError ? ColorTokens.destructive : (isFocused ? ColorTokens.accentPrimary : Color(UIColor.separator)),
                    lineWidth: isFocused || isError ? 2 : 1
                )
                .frame(width: 44, height: 52)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.medium)
                        .fill(ColorTokens.backgroundSecondary)
                )

            Text(text)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(ColorTokens.textPrimary)
        }
        .contentShape(Rectangle())
    }
}

