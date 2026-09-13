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

    @State private var selectedSuggestion: String = "Dành cho bạn"
    @State private var isScrolled: Bool = false

    private let mockSuggestions = [
        "Dành cho bạn", "Nhiếp ảnh", "Du lịch", "Thời trang",
        "Ẩm thực", "Âm nhạc", "Thể thao", "Kiến trúc", "Công nghệ", "Nghệ thuật"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar & Search Suggestions Header
            exploreHeaderView

            // Search results overlay or Explore Grid
            if !viewModel.searchText.isEmpty {
                searchResultsList
            } else {
                exploreGrid
            }
        }
        .onChange(of: viewModel.searchText) { _, _ in
            Task { await viewModel.search() }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if viewModel.explorePosts.isEmpty {
                await viewModel.loadExplore()
            }
        }
    }

    // MARK: - Explore Header View (SearchBar + Trailing Button + Suggestion Pills)

    private var exploreHeaderView: some View {
        VStack(spacing: DS.Spacing.xs) {
            // Top row: SearchBar expanding to fill space + Trailing button
            HStack(spacing: DS.Spacing.xs) {
                // Expanding Search Bar
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .font(DS.Font.subheadline)
                        .foregroundStyle(.secondary)

                    TextField(L10n.Common.search, text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(DS.Font.subheadline)

                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(DS.Font.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xs)
                .background(ColorTokens.backgroundSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.input))

                // Trailing button
                Button {
                    // Explore map/filter action
                } label: {
                    Image(systemName: "map")
                        .font(.title3)
                        .foregroundStyle(Color.primary)
                }
            }
            .padding(.horizontal, DS.Padding.horizontal)

            // Bottom row: ScrollView displaying search suggestion pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.xs) {
                    ForEach(mockSuggestions, id: \.self) { suggestion in
                        let isSelected = selectedSuggestion == suggestion
                        Button {
                            selectedSuggestion = suggestion
                            if suggestion != "Dành cho bạn" {
                                viewModel.searchText = suggestion
                            } else {
                                viewModel.searchText = ""
                            }
                        } label: {
                            Text(suggestion)
                                .font(DS.Font.captionBold)
                                .padding(.horizontal, DS.Spacing.sm)
                                .padding(.vertical, DS.Spacing.xxs)
                                .background(
                                    isSelected ? Color.primary : ColorTokens.backgroundSecondary,
                                    in: RoundedRectangle(cornerRadius: DS.Radius.medium)
                                )
                                .foregroundStyle(isSelected ? Color(.systemBackground) : Color.primary)
                        }
                    }
                }
                .padding(.horizontal, DS.Padding.horizontal)
            }
            .padding(.bottom, DS.Spacing.xxs)

            if isScrolled {
                Divider()
                    .opacity(DS.Opacity.divider)
            }
        }
        .padding(.top, DS.Spacing.xxs)
        .background {
            if isScrolled {
                Color(.systemBackground)
            } else {
                Color.clear
            }
        }
        .animation(DS.Animation.standard, value: isScrolled)
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
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { _, newOffset in
            let atTop = newOffset <= Constants.scrollThresholdTop
            if atTop != !isScrolled {
                withAnimation(DS.Animation.standard) {
                    isScrolled = !atTop
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
                Text(L10n.Explore.noResults)
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

// MARK: - ExploreScrollOffsetPreferenceKey

private struct ExploreScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Constants

private enum Constants {
    static let scrollThresholdTop: CGFloat = 10
}
