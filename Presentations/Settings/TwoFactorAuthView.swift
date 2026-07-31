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
                    Label("Two-Factor Authentication", systemImage: "shield.checkered")
                }
            }

            if isTwoFactorEnabled {
                Section("Authentication Method") {
                    ForEach(TwoFactorMethod.allCases, id: \.self) { method in
                        HStack {
                            Label(method.title, systemImage: method.icon)
                            Spacer()
                            if selectedMethod == method {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(ColorTokens.accentPrimary)
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
        .navigationTitle("Two-Factor Authentication")
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

    var icon: String {
        switch self {
        case .sms: return "message"
        case .authenticatorApp: return "lock.shield"
        }
    }
}
