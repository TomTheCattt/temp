//
//  ResetPasswordView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI

// MARK: - ResetPasswordView

struct ResetPasswordView: View {

    @State private var viewModel: ResetPasswordViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        viewModel: ResetPasswordViewModel,
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

                    InstagramIcon(.system(name: "lock.shield"), size: 44, color: ColorTokens.accentPrimary)
                }
                .padding(.bottom, DS.Spacing.xxxl)

                // MARK: Title & Description
                VStack(spacing: DS.Spacing.sm) {
                    Text(L10n.ResetPassword.title)
                        .font(DS.Font.title2)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(L10n.ResetPassword.description)
                        .font(DS.Font.body)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Padding.horizontal)
                }
                .padding(.bottom, DS.Spacing.xl)

                // MARK: Form
                VStack(spacing: DS.Spacing.md) {
                    FloatingTextField(
                        placeholder: L10n.ResetPassword.newPasswordPlaceholder,
                        text: $viewModel.newPassword,
                        isSecure: true,
                        textContentType: .newPassword
                    )
                    .errorShake(trigger: viewModel.errorMessage)

                    FloatingTextField(
                        placeholder: L10n.ResetPassword.confirmPasswordPlaceholder,
                        text: $viewModel.confirmPassword,
                        isSecure: true,
                        textContentType: .newPassword
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

                // MARK: Reset Button
                Button {
                    Task {
                        await viewModel.resetPassword()
                        if viewModel.isReset {
                            onSuccess?()
                        }
                    }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(L10n.ResetPassword.resetButton)
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
                .padding(.top, DS.Spacing.lg)

                Spacer()
                Spacer()

                // MARK: Back to Login
                Button {
                    dismiss()
                } label: {
                    Text(L10n.ResetPassword.backToLogin)
                        .font(DS.Font.headline)
                        .foregroundStyle(ColorTokens.accentPrimary)
                }
                .padding(.bottom, DS.Spacing.md)
            }
            .navigationTitle(L10n.ResetPassword.navTitle)
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
            .alert(L10n.ResetPassword.successTitle, isPresented: $viewModel.showSuccessAlert) {
                Button(L10n.Common.ok) {
                    dismiss()
                }
            } message: {
                Text(L10n.ResetPassword.successMessage)
            }
        }
    }
}
