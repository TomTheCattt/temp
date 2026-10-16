//
//  TwoFactorAuthView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI

// MARK: - TwoFactorAuthView

struct TwoFactorAuthView: View {

    @State private var isTwoFactorEnabled = false
    @State private var selectedMethod: TwoFactorMethod = .sms

    var body: some View {
        List {
            Section {
                Text("Two-factor authentication adds an extra layer of security to your account. You'll need to enter a code in addition to your password each time you log in.")
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            Section {
                Toggle(isOn: $isTwoFactorEnabled) {
                    HStack(spacing: DS.Spacing.sm) {
                        InstagramIcon(.lock, size: DS.Size.iconDefault)
                        Text("Two-Factor Authentication")
                    }
                }
            }

            if isTwoFactorEnabled {
                Section("Authentication Method") {
                    ForEach(TwoFactorMethod.allCases, id: \.self) { method in
                        HStack(spacing: DS.Spacing.sm) {
                            InstagramIcon(method.appIcon, size: DS.Size.iconDefault)
                            Text(method.title)
                            Spacer()
                            if selectedMethod == method {
                                InstagramIcon(.system(name: "checkmark"), size: DS.Size.iconSmall, color: ColorTokens.accentPrimary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedMethod = method
                        }
                    }
                }
            }
        }
        .navigationTitle(L10n.Settings.twoFactor)
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - TwoFactorMethod

private enum TwoFactorMethod: CaseIterable {
    case sms
    case authenticatorApp

    var title: String {
        switch self {
        case .sms: return "Text Message (SMS)"
        case .authenticatorApp: return "Authenticator App"
        }
    }

    var appIcon: AppIcon {
        switch self {
        case .sms: return .comment
        case .authenticatorApp: return .lock
        }
    }
}
