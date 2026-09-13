//
//  SavedPostsView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI

// MARK: - SavedPostsView

struct SavedPostsView: View {

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: DS.Spacing.xxxs),
                    GridItem(.flexible(), spacing: DS.Spacing.xxxs),
                    GridItem(.flexible(), spacing: DS.Spacing.xxxs)
                ],
                spacing: DS.Spacing.xxxs
            ) {
                // Placeholder content
                ForEach(0..<12, id: \.self) { _ in
                    Rectangle()
                        .fill(ColorTokens.backgroundSubtler)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .navigationTitle(L10n.Settings.saved)
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if true { // TODO: Replace with actual empty state check
                ContentUnavailableView(
                    L10n.Settings.savedEmptyTitle,
                    systemImage: "bookmark",
                    description: Text(L10n.Settings.savedEmptyDescription)
                )
            }
        }
    }
}
