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
                Text("People you add to your close friends list will be able to see your close friends stories.")
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            Section("Close Friends") {
                // TODO: Populate with actual close friends data
                ContentUnavailableView(
                    "No Close Friends",
                    systemImage: "star.circle",
                    description: Text("Add people to your close friends list to share stories exclusively with them.")
                )
            }
        }
        .navigationTitle("Close Friends")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search")
    }
}
