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
                SecureField("Current Password", text: $currentPassword)
                    .textContentType(.password)
            }

            Section {
                SecureField("New Password", text: $newPassword)
                    .textContentType(.newPassword)
                SecureField("Confirm New Password", text: $confirmPassword)
                    .textContentType(.newPassword)
            } footer: {
                Text("Your password must be at least 6 characters and should include a combination of numbers, letters, and special characters.")
                    .font(DS.Font.caption)
            }
        }
        .navigationTitle("Password")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
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
        .alert("Error", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your password has been changed successfully.")
        }
    }

    private var isFormValid: Bool {
        !currentPassword.isEmpty
        && newPassword.count >= 6
        && newPassword == confirmPassword
    }
}
