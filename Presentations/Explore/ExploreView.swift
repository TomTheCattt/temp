//
//  ExploreView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import NukeUI

// MARK: - ExploreView

struct ExploreView: View {

    @State private var viewModel = ExploreViewModel(
        postRepository: DIContainer.shared.resolve(PostRepositoryProtocol.self),
        searchUsersUseCase: DIContainer.shared.resolve(SearchUsersUseCaseProtocol.self)
    )

    var body: some View {
        VStack(spacing: 0) {
            // Search results overlay
            if !viewModel.searchText.isEmpty {
                searchResultsList
            } else {
                exploreGrid
            }
        }
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: L10n.Common.search
        )
        .onChange(of: viewModel.searchText) { _, _ in
            Task { await viewModel.search() }
        }
        .navigationTitle(L10n.Tab.explore)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.explorePosts.isEmpty {
                await viewModel.loadExplore()
            }
        }
    }

    // MARK: - Explore Grid

    private var exploreGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: exploreColumns,
                spacing: DS.Size.gridSpacing
            ) {
                ForEach(Array(viewModel.explorePosts.enumerated()), id: \.element.id) { index, post in
                    ExploreGridItem(post: post, index: index)
                        .onTapGesture {
                            AppRouter.shared.push(.postDetail(postId: post.id))
                        }
                }
            }
        }
    }

    private var exploreColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: DS.Size.gridSpacing),
            GridItem(.flexible(), spacing: DS.Size.gridSpacing),
            GridItem(.flexible(), spacing: DS.Size.gridSpacing)
        ]
    }

    // MARK: - Search Results

    private var searchResultsList: some View {
        List {
            if viewModel.isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            } else if viewModel.searchResults.isEmpty && viewModel.searchText.count >= 2 {
                Text("No results found")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(viewModel.searchResults) { user in
                    SearchResultRow(user: user)
                        .onTapGesture {
                            AppRouter.shared.push(.userProfile(userId: user.id))
                        }
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - ExploreGridItem

private struct ExploreGridItem: View {
    let post: Post
    let index: Int

    /// Instagram uses a pattern: every 3rd item in a group is larger (spanning 2 rows).
    /// Simplified here as uniform squares.
    var body: some View {
        if let media = post.mediaItems.first {
            LazyImage(url: media.thumbnailURL ?? media.url) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                } else {
                    ColorTokens.backgroundSecondary
                }
            }
            .aspectRatio(1, contentMode: .fill)
            .clipped()
            .overlay(alignment: .topTrailing) {
                if post.mediaItems.count > 1 {
                    Image(systemName: "square.on.square")
                        .font(DS.Font.caption)
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                        .padding(DS.Spacing.iconGap)
                }
            }
        }
    }
}

// MARK: - SearchResultRow

private struct SearchResultRow: View {
    let user: User

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            LazyImage(url: user.avatarURL) { state in
                if let image = state.image {
                    image.resizable()
                } else {
                    Circle().fill(ColorTokens.buttonSecondary)
                }
            }
            .frame(width: DS.Size.avatarList, height: DS.Size.avatarList)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                HStack(spacing: DS.Spacing.xxs) {
                    Text(user.username)
                        .font(DS.Font.subheadline)
                        .fontWeight(.semibold)

                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(DS.Font.caption2)
                            .foregroundStyle(ColorTokens.accentPrimary)
                    }
                }

                Text(user.fullName)
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }
}
