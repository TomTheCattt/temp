//
//  BlockedAccountsView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI

// MARK: - BlockedAccountsView

struct BlockedAccountsView: View {

    var body: some View {
        List {
            Section {
                Text(L10n.Settings.blockedFooter)
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            Section {
                // TODO: Populate with actual blocked accounts
                ContentUnavailableView(
                    L10n.Settings.blockedEmptyTitle,
                    systemImage: "nosign",
                    description: Text(L10n.Settings.blockedEmptyDescription)
                )
            }
        }
        .navigationTitle(L10n.Settings.blockedAccounts)
        .navigationBarTitleDisplayMode(.large)
    }
}
