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
                Text("Blocked people can't find your profile, posts, or stories. They won't be notified that you blocked them.")
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            Section {
                // TODO: Populate with actual blocked accounts
                ContentUnavailableView(
                    "No Blocked Accounts",
                    systemImage: "nosign",
                    description: Text("You haven't blocked anyone yet.")
                )
            }
        }
        .navigationTitle("Blocked Accounts")
        .navigationBarTitleDisplayMode(.large)
    }
}
