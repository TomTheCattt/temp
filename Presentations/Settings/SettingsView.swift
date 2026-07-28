//
//  SettingsView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {

    @State private var viewModel: SettingsViewModel
    @State private var showLogoutConfirmation = false

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            // Account
            accountSection

            // Appearance
            appearanceSection

            // Notifications
            notificationsSection

            // Privacy
            privacySection

            // Security
            securitySection

            // Data & Storage
            dataSection

            // About
            aboutSection

            // Logout
            logoutSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadSettings()
        }
        .confirmationDialog("Log Out", isPresented: $showLogoutConfirmation) {
            Button("Log Out", role: .destructive) {
                Task { await viewModel.logout() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to log out?")
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section("Account") {
            NavigationLink(value: AppRoute.editProfile) {
                Label("Edit Profile", systemImage: "person.circle")
            }

            Label("Saved", systemImage: "bookmark")

            Label("Close Friends", systemImage: "star.circle")

            Label("Blocked Accounts", systemImage: "nosign")
        }
    }

    // MARK: - Appearance Section

    @State private var themeManager = ThemeManager.shared

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker(selection: $themeManager.themeMode) {
                ForEach(AppThemeMode.allCases, id: \.self) { mode in
                    Label(mode.displayName, systemImage: mode.icon)
                        .tag(mode)
                }
            } label: {
                Label("Theme", systemImage: "paintbrush")
            }
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle(isOn: $viewModel.isPushEnabled) {
                Label("Push Notifications", systemImage: "bell")
            }

            if viewModel.isPushEnabled {
                Toggle("Likes", isOn: $viewModel.isLikeNotificationEnabled)
                Toggle("Comments", isOn: $viewModel.isCommentNotificationEnabled)
                Toggle("New Followers", isOn: $viewModel.isFollowNotificationEnabled)
                Toggle("Direct Messages", isOn: $viewModel.isDirectMessageNotificationEnabled)
            }
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        Section("Privacy") {
            Toggle(isOn: $viewModel.isPrivateAccount) {
                Label("Private Account", systemImage: "lock")
            }
            .onChange(of: viewModel.isPrivateAccount) { _, _ in
                Task { await viewModel.togglePrivateAccount() }
            }

            Toggle(isOn: $viewModel.isActivityStatusVisible) {
                Label("Activity Status", systemImage: "circle.fill")
            }
        }
    }

    // MARK: - Security Section

    private var securitySection: some View {
        Section("Security") {
            Toggle(isOn: $viewModel.isBiometricEnabled) {
                Label("Face ID / Touch ID", systemImage: "faceid")
            }

            Label("Password", systemImage: "key")

            Label("Two-Factor Authentication", systemImage: "shield.checkered")
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        Section("Data & Storage") {
            Toggle(isOn: $viewModel.isHighQualityUploads) {
                Label("High Quality Uploads", systemImage: "arrow.up.circle")
            }

            Toggle(isOn: $viewModel.isCellularDataEnabled) {
                Label("Use Cellular Data", systemImage: "antenna.radiowaves.left.and.right")
            }

            Button(action: {}) {
                Label("Clear Cache", systemImage: "trash")
                    .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("App Version", value: "1.0.0")

            Label("Terms of Service", systemImage: "doc.text")

            Label("Privacy Policy", systemImage: "hand.raised")

            Label("Open Source Licenses", systemImage: "chevron.left.forwardslash.chevron.right")
        }
    }

    // MARK: - Logout Section

    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isLoggingOut {
                        ProgressView()
                    } else {
                        Text("Log Out")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .disabled(viewModel.isLoggingOut)
        }
    }
}
