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
        postRepository: PostRepository(),
        searchUsersUseCase: SearchUsersUseCase(userRepository: UserRepository())
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
            prompt: "Search"
        )
        .onChange(of: viewModel.searchText) { _, _ in
            Task { await viewModel.search() }
        }
        .navigationTitle("Explore")
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
                spacing: 2
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
            GridItem(.flexible(), spacing: 2),
            GridItem(.flexible(), spacing: 2),
            GridItem(.flexible(), spacing: 2)
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
                    Color(.systemGray6)
                }
            }
            .aspectRatio(1, contentMode: .fill)
            .clipped()
            .overlay(alignment: .topTrailing) {
                if post.mediaItems.count > 1 {
                    Image(systemName: "square.on.square")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                        .padding(6)
                }
            }
        }
    }
}

// MARK: - SearchResultRow

private struct SearchResultRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            LazyImage(url: user.avatarURL) { state in
                if let image = state.image {
                    image.resizable()
                } else {
                    Circle().fill(Color(.systemGray5))
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(user.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }

                Text(user.fullName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }
}
