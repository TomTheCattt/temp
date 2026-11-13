//
//  NotificationPreferencesView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI

// MARK: - NotificationPreferencesView

struct NotificationPreferencesView: View {

    @State private var viewModel = NotificationPreferencesViewModel(
        userSettingsUseCase: DIContainer.shared.resolve(UserSettingsUseCaseProtocol.self)
    )

    var body: some View {
        List {
            // MARK: - What You See
            Section {
                ForEach(NotificationPreferencesViewModel.PreferenceCategory.WhatYouSee.allCases, id: \.self) { item in
                    PreferenceRow(
                        title: item.title,
                        subtitle: item.subtitle,
                        isOn: Binding(
                            get: { viewModel.preferences[item.key] ?? false },
                            set: { viewModel.updatePreference(key: item.key, value: $0) }
                        )
                    )
                }
            } header: {
                Text(L10n.NotificationPreferences.whatYouSee)
                    .textCase(.uppercase)
                    .font(DS.Font.captionBold)
            }

            // MARK: - Interactions
            Section {
                ForEach(NotificationPreferencesViewModel.PreferenceCategory.Interactions.allCases, id: \.self) { item in
                    PreferenceRow(
                        title: item.title,
                        subtitle: item.subtitle,
                        isOn: Binding(
                            get: { viewModel.preferences[item.key] ?? false },
                            set: { viewModel.updatePreference(key: item.key, value: $0) }
                        )
                    )
                }
            } header: {
                Text(L10n.NotificationPreferences.interactions)
                    .textCase(.uppercase)
                    .font(DS.Font.captionBold)
            }

            // MARK: - Messages & Calls
            Section {
                ForEach(NotificationPreferencesViewModel.PreferenceCategory.MessagesCalls.allCases, id: \.self) { item in
                    PreferenceRow(
                        title: item.title,
                        subtitle: item.subtitle,
                        isOn: Binding(
                            get: { viewModel.preferences[item.key] ?? false },
                            set: { viewModel.updatePreference(key: item.key, value: $0) }
                        )
                    )
                }
            } header: {
                Text(L10n.NotificationPreferences.messagesCalls)
                    .textCase(.uppercase)
                    .font(DS.Font.captionBold)
            }

            // MARK: - Live & IGTV
            Section {
                ForEach(NotificationPreferencesViewModel.PreferenceCategory.LiveIGTV.allCases, id: \.self) { item in
                    PreferenceRow(
                        title: item.title,
                        subtitle: item.subtitle,
                        isOn: Binding(
                            get: { viewModel.preferences[item.key] ?? false },
                            set: { viewModel.updatePreference(key: item.key, value: $0) }
                        )
                    )
                }
            } header: {
                Text(L10n.NotificationPreferences.liveIGTV)
                    .textCase(.uppercase)
                    .font(DS.Font.captionBold)
            }

            // MARK: - Other
            Section {
                ForEach(NotificationPreferencesViewModel.PreferenceCategory.Other.allCases, id: \.self) { item in
                    PreferenceRow(
                        title: item.title,
                        subtitle: item.subtitle,
                        isOn: Binding(
                            get: { viewModel.preferences[item.key] ?? false },
                            set: { viewModel.updatePreference(key: item.key, value: $0) }
                        )
                    )
                }
            } header: {
                Text(L10n.NotificationPreferences.other)
                    .textCase(.uppercase)
                    .font(DS.Font.captionBold)
            }

            // MARK: - Email & SMS
            Section {
                NavigationLink {
                    EmailSMSSettingsView()
                } label: {
                    HStack {
                        Text(L10n.NotificationPreferences.emailSMSTitle)
                        Spacer()
                        InstagramIcon(.chevronRight, size: DS.Size.iconSmall, color: .secondary)
                    }
                }

                NavigationLink {
                    PushNotificationSettingsView()
                } label: {
                    HStack {
                        Text(L10n.NotificationPreferences.pushTitle)
                        Spacer()
                        InstagramIcon(.chevronRight, size: DS.Size.iconSmall, color: .secondary)
                    }
                }
            } header: {
                Text(L10n.NotificationPreferences.deliveryMethods)
                    .textCase(.uppercase)
                    .font(DS.Font.captionBold)
            }
        }
        .navigationTitle(L10n.NotificationPreferences.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    HapticFeedbackSafe.impact(.light)
                    AppRouter.shared.pop()
                } label: {
                    InstagramIcon(.chevronLeft, size: 20, color: Color.primary)
                }
            }
        }
        .task {
            await viewModel.loadPreferences()
        }
    }
}

// MARK: - Preference Row

private struct PreferenceRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                Text(title)
                    .font(DS.Font.body)
                Text(subtitle)
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(ColorTokens.accentPrimary)
        }
        .padding(.vertical, DS.Spacing.xxs)
    }
}

// MARK: - Email & SMS Settings View

private struct EmailSMSSettingsView: View {
    var body: some View {
        List {
            Section {
                ForEach(EmailSMSItem.allCases, id: \.self) { item in
                    PreferenceRow(
                        title: item.title,
                        subtitle: item.subtitle,
                        isOn: .constant(false) // Would bind to actual settings
                    )
                }
            } header: {
                Text(L10n.NotificationPreferences.emailSettings)
                    .textCase(.uppercase)
                    .font(DS.Font.captionBold)
            }

            Section {
                ForEach(SMSItem.allCases, id: \.self) { item in
                    PreferenceRow(
                        title: item.title,
                        subtitle: item.subtitle,
                        isOn: .constant(false)
                    )
                }
            } header: {
                Text(L10n.NotificationPreferences.smsSettings)
                    .textCase(.uppercase)
                    .font(DS.Font.captionBold)
            }
        }
        .navigationTitle(L10n.NotificationPreferences.emailSMSTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum EmailSMSItem: CaseIterable {
    case newFollower
    case likes
    case comments
    case mentions
    case directMessages
    case liveVideos
    case igtv

    var title: String {
        switch self {
        case .newFollower: return "New Followers"
        case .likes: return "Likes"
        case .comments: return "Comments"
        case .mentions: return "Mentions"
        case .directMessages: return "Direct Messages"
        case .liveVideos: return "Live Videos"
        case .igtv: return "IGTV"
        }
    }

    var subtitle: String {
        switch self {
        case .newFollower: return "Get emails when someone follows you"
        case .likes: return "Get emails when someone likes your posts"
        case .comments: return "Get emails when someone comments on your posts"
        case .mentions: return "Get emails when you're mentioned"
        case .directMessages: return "Get emails for new messages"
        case .liveVideos: return "Get emails when accounts you follow go live"
        case .igtv: return "Get emails for new IGTV videos"
        }
    }
}

private enum SMSItem: CaseIterable {
    case loginCodes
    case securityAlerts

    var title: String {
        switch self {
        case .loginCodes: return "Login Codes"
        case .securityAlerts: return "Security Alerts"
        }
    }

    var subtitle: String {
        switch self {
        case .loginCodes: return "Receive login codes via SMS"
        case .securityAlerts: return "Receive security alerts via SMS"
        }
    }
}

// MARK: - Push Notification Settings View

private struct PushNotificationSettingsView: View {
    var body: some View {
        List {
            Section {
                PreferenceRow(
                    title: L10n.NotificationPreferences.pushEnabled,
                    subtitle: L10n.NotificationPreferences.pushEnabledSubtitle,
                    isOn: .constant(true)
                )
            } header: {
                Text(L10n.NotificationPreferences.pushSettings)
                    .textCase(.uppercase)
                    .font(DS.Font.captionBold)
            }

            Section {
                ForEach(PushCategory.allCases, id: \.self) { category in
                    NavigationLink {
                        PushCategoryDetailView(category: category)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                                Text(category.title)
                                    .font(DS.Font.body)
                                Text(category.subtitle)
                                    .font(DS.Font.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            InstagramIcon(.chevronRight, size: DS.Size.iconSmall, color: .secondary)
                        }
                        .padding(.vertical, DS.Spacing.xxs)
                    }
                }
            } header: {
                Text(L10n.NotificationPreferences.pushCategories)
                    .textCase(.uppercase)
                    .font(DS.Font.captionBold)
            }
        }
        .navigationTitle(L10n.NotificationPreferences.pushTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum PushCategory: CaseIterable {
    case likes
    case comments
    case follows
    case mentions
    case directMessages
    case liveVideos
    case reels
    case posts
    case stories
    case igtv
    case shop
    case fundraisers

    var title: String {
        switch self {
        case .likes: return "Likes"
        case .comments: return "Comments"
        case .follows: return "Follows & Follow Requests"
        case .mentions: return "Mentions"
        case .directMessages: return "Direct Messages"
        case .liveVideos: return "Live Videos"
        case .reels: return "Reels"
        case .posts: return "Posts"
        case .stories: return "Stories"
        case .igtv: return "IGTV"
        case .shop: return "Shop"
        case .fundraisers: return "Fundraisers"
        }
    }

    var subtitle: String {
        switch self {
        case .likes: return "When someone likes your post"
        case .comments: return "When someone comments on your post"
        case .follows: return "New followers and follow requests"
        case .mentions: return "When you're mentioned in a post or comment"
        case .directMessages: return "New messages and message requests"
        case .liveVideos: return "When accounts you follow go live"
        case .reels: return "New Reels from accounts you follow"
        case .posts: return "New posts from accounts you follow"
        case .stories: return "New Stories from accounts you follow"
        case .igtv: return "New IGTV videos"
        case .shop: return "Updates about shops you follow"
        case .fundraisers: return "Fundraisers from accounts you follow"
        }
    }
}

private struct PushCategoryDetailView: View {
    let category: PushCategory

    @State private var enablePush = true
    @State private var enableEmail = false
    @State private var frequency: Frequency = .immediate

    enum Frequency: String, CaseIterable {
        case immediate = "Immediate"
        case daily = "Daily Summary"
        case weekly = "Weekly Summary"
        case off = "Off"
    }

    var body: some View {
        List {
            Section {
                Toggle(L10n.NotificationPreferences.pushNotifications, isOn: $enablePush)
                Toggle(L10n.NotificationPreferences.emailNotifications, isOn: $enableEmail)
            } header: {
                Text(L10n.NotificationPreferences.deliveryMethods)
                    .textCase(.uppercase)
                    .font(DS.Font.captionBold)
            }

            Section {
                Picker(L10n.NotificationPreferences.frequency, selection: $frequency) {
                    ForEach(Frequency.allCases, id: \.self) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }
            } header: {
                Text(L10n.NotificationPreferences.frequency)
                    .textCase(.uppercase)
                    .font(DS.Font.captionBold)
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - ViewModel

