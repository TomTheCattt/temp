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
        .navigationTitle(L10n.Settings.title)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadSettings()
        }
        .confirmationDialog(L10n.Auth.logoutConfirmTitle, isPresented: $showLogoutConfirmation) {
            Button(L10n.Settings.logOut, role: .destructive) {
                Task { await viewModel.logout() }
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Auth.logoutConfirmMessage)
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section(L10n.Settings.account) {
            NavigationLink(value: AppRoute.editProfile) {
                Label(L10n.Settings.editProfile, systemImage: "person.circle")
            }

            Label(L10n.Settings.saved, systemImage: "bookmark")

            Label(L10n.Settings.closeFriends, systemImage: "star.circle")

            Label(L10n.Settings.blockedAccounts, systemImage: "nosign")
        }
    }

    // MARK: - Appearance Section

    @State private var themeManager = ThemeManager.shared

    private var appearanceSection: some View {
        Section(L10n.Settings.appearance) {
            Picker(selection: $themeManager.themeMode) {
                ForEach(AppThemeMode.allCases, id: \.self) { mode in
                    Label(mode.displayName, systemImage: mode.icon)
                        .tag(mode)
                }
            } label: {
                Label(L10n.Settings.theme, systemImage: "paintbrush")
            }
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section(L10n.Settings.notifications) {
            Toggle(isOn: $viewModel.isPushEnabled) {
                Label(L10n.Settings.pushNotifications, systemImage: "bell")
            }

            if viewModel.isPushEnabled {
                Toggle(L10n.Settings.likes, isOn: $viewModel.isLikeNotificationEnabled)
                Toggle(L10n.Settings.comments, isOn: $viewModel.isCommentNotificationEnabled)
                Toggle(L10n.Settings.newFollowers, isOn: $viewModel.isFollowNotificationEnabled)
                Toggle(L10n.Settings.directMessages, isOn: $viewModel.isDirectMessageNotificationEnabled)
            }
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        Section(L10n.Settings.privacy) {
            Toggle(isOn: $viewModel.isPrivateAccount) {
                Label(L10n.Settings.privateAccount, systemImage: "lock")
            }
            .onChange(of: viewModel.isPrivateAccount) { _, _ in
                Task { await viewModel.togglePrivateAccount() }
            }

            Toggle(isOn: $viewModel.isActivityStatusVisible) {
                Label(L10n.Settings.activityStatus, systemImage: "circle.fill")
            }
        }
    }

    // MARK: - Security Section

    private var securitySection: some View {
        Section(L10n.Settings.security) {
            Toggle(isOn: $viewModel.isBiometricEnabled) {
                Label(L10n.Settings.faceIdTouchId, systemImage: "faceid")
            }

            Label(L10n.Settings.password, systemImage: "key")

            Label(L10n.Settings.twoFactor, systemImage: "shield.checkered")
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        Section(L10n.Settings.dataStorage) {
            Toggle(isOn: $viewModel.isHighQualityUploads) {
                Label(L10n.Settings.highQualityUploads, systemImage: "arrow.up.circle")
            }

            Toggle(isOn: $viewModel.isCellularDataEnabled) {
                Label(L10n.Settings.useCellularData, systemImage: "antenna.radiowaves.left.and.right")
            }

            Button(action: {}) {
                Label(L10n.Settings.clearCache, systemImage: "trash")
                    .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section(L10n.Settings.about) {
            LabeledContent(L10n.Settings.appVersion, value: "1.0.0")

            Label(L10n.Settings.termsOfService, systemImage: "doc.text")

            Label(L10n.Settings.privacyPolicy, systemImage: "hand.raised")

            Label(L10n.Settings.openSourceLicenses, systemImage: "chevron.left.forwardslash.chevron.right")
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
                        Text(L10n.Settings.logOut)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .disabled(viewModel.isLoggingOut)
        }
    }
}
