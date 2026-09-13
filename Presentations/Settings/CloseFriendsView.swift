//
//  CloseFriendsView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI

// MARK: - CloseFriendsView

struct CloseFriendsView: View {

    @State private var searchText = ""

    var body: some View {
        List {
            Section {
                Text(L10n.Settings.closeFriendsFooter)
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            Section(L10n.Settings.closeFriends) {
                // TODO: Populate with actual close friends data
                ContentUnavailableView(
                    L10n.Settings.closeFriendsEmptyTitle,
                    systemImage: "star.circle",
                    description: Text(L10n.Settings.closeFriendsEmptyDescription)
                )
            }
        }
        .navigationTitle(L10n.Settings.closeFriends)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: L10n.Common.search)
    }
}
