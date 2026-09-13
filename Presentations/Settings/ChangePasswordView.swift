//
//  ChangePasswordView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI

// MARK: - ChangePasswordView

struct ChangePasswordView: View {

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                SecureField(L10n.ChangePassword.currentPassword, text: $currentPassword)
                    .textContentType(.password)
            }

            Section {
                SecureField(L10n.ChangePassword.newPassword, text: $newPassword)
                    .textContentType(.newPassword)
                SecureField(L10n.ChangePassword.confirmNewPassword, text: $confirmPassword)
                    .textContentType(.newPassword)
            } footer: {
                Text(L10n.ChangePassword.requirementsFooter)
                    .font(DS.Font.caption)
            }
        }
        .navigationTitle(L10n.ChangePassword.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.Common.save) {
                    // TODO: Implement password change
                }
                .fontWeight(.semibold)
                .disabled(!isFormValid || isSaving)
            }
        }
        .overlay {
            if isSaving {
                ProgressView()
            }
        }
        .alert(L10n.Common.error, isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(L10n.Common.ok) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .alert(L10n.ChangePassword.successTitle, isPresented: $showSuccess) {
            Button(L10n.Common.ok) { dismiss() }
        } message: {
            Text(L10n.ChangePassword.successMessage)
        }
    }

    private var isFormValid: Bool {
        !currentPassword.isEmpty
        && newPassword.count >= 6
        && newPassword == confirmPassword
    }
}
