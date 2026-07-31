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
        .navigationTitle("Saved")
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if true { // TODO: Replace with actual empty state check
                ContentUnavailableView(
                    "No Saved Posts",
                    systemImage: "bookmark",
                    description: Text("Save photos and videos that you want to see again.")
                )
            }
        }
    }
}
