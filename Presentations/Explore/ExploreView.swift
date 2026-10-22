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

    @FocusState private var isSearchFocused: Bool
    @State private var isScrolled: Bool = false

    private let mockSuggestions = [
        "Dành cho bạn", "Nhiếp ảnh", "Du lịch", "Thời trang",
        "Ẩm thực", "Âm nhạc", "Thể thao", "Kiến trúc", "Công nghệ", "Nghệ thuật"
    ]

    private var isSearchActive: Bool {
        isSearchFocused || !viewModel.searchText.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar & Search Suggestions Header
            exploreHeaderView

            // Search results overlay or Explore Grid
            if isSearchActive {
                searchResultsList
            } else {
                exploreGrid
            }
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
            // Top row: SearchBar expanding to fill space + Trailing button (Cancel or Map)
            HStack(spacing: DS.Spacing.xs) {
                // Expanding Search Bar
                HStack(spacing: DS.Spacing.xs) {
                    InstagramIcon(.search(selected: false), size: DS.Size.iconSmall, color: ColorTokens.textSecondary)

                    TextField(L10n.Common.search, text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(DS.Font.subheadline)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            submitSearch()
                        }

                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            InstagramIcon(.system(name: "xmark.circle.fill"), size: DS.Size.iconSmall, color: ColorTokens.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xs)
                .background(ColorTokens.backgroundSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.input))

                // Trailing button (Cancel when search is active, Map icon when browsing)
                if isSearchActive {
                    Button(L10n.Common.cancel) {
                        withAnimation(DS.Animation.fast) {
                            isSearchFocused = false
                            viewModel.clearSearch()
                            hideKeyboard()
                        }
                    }
                    .font(DS.Font.subheadline)
                    .foregroundStyle(Color.primary)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    Button {
                        HapticFeedbackSafe.impact(.light)
                        // Explore map/filter action
                    } label: {
                        InstagramIcon(.system(name: "map"), size: DS.Size.iconDefault, color: ColorTokens.textPrimary)
                            .frame(width: 44, height: 44, alignment: .trailing)
                            .contentShape(Rectangle())
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, DS.Padding.horizontal)

            // Bottom row: Category suggestion pills (hidden when actively searching to maximize space)
            if !isSearchActive {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.xs) {
                        ForEach(mockSuggestions, id: \.self) { suggestion in
                            let isSelected = viewModel.selectedCategory == suggestion
                            Button {
                                withAnimation(DS.Animation.fast) {
                                    viewModel.selectCategory(suggestion)
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
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

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
        .animation(DS.Animation.fast, value: isSearchActive)
    }

    // MARK: - Actions

    private func submitSearch() {
        let query = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        hideKeyboard()
        AppRouter.shared.push(.searchResults(query: query))
    }

    // MARK: - Explore Grid

    private var exploreGrid: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.explorePosts.isEmpty {
                ProgressView()
                    .padding(.top, DS.Spacing.xxxl)
            } else {
                LazyVGrid(
                    columns: exploreColumns,
                    spacing: DS.Size.gridSpacing
                ) {
                    ForEach(Array(viewModel.filteredExplorePosts.enumerated()), id: \.element.id) { index, post in
                        ExploreGridItem(post: post, index: index)
                            .onTapGesture {
                                AppRouter.shared.push(.postDetail(postId: post.id))
                            }
                            .onAppear {
                                if index == viewModel.filteredExplorePosts.count - 1 {
                                    Task { await viewModel.loadMoreExplore() }
                                }
                            }
                    }
                }
                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding(.vertical, DS.Spacing.md)
                }
            }
        }
        .refreshable {
            await viewModel.loadExplore()
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
        .scrollDismissesKeyboard(.interactively)
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
                .padding(.top, DS.Spacing.xl)
            } else if viewModel.searchText.isEmpty {
                // Search hint when user just focused search bar
                VStack(spacing: DS.Spacing.sm) {
                    InstagramIcon(.search(selected: false), size: DS.Size.iconHero, color: ColorTokens.textSecondary.opacity(0.6))
                    Text("Tìm kiếm tài khoản, bài viết, thẻ hashtag...")
                        .font(DS.Font.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, DS.Spacing.xxxl)
                .listRowSeparator(.hidden)
            } else if viewModel.searchText.count < 2 {
                // Hint for short query
                HStack(spacing: DS.Spacing.xs) {
                    Spacer()
                    InstagramIcon(.system(name: "info.circle"), size: DS.Size.iconSmall, color: ColorTokens.textSecondary)
                    Text("Nhập ít nhất 2 ký tự để tìm kiếm")
                        .font(DS.Font.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .padding(.top, DS.Spacing.xl)
            } else if viewModel.searchResults.isEmpty {
                // No results
                VStack(spacing: DS.Spacing.xs) {
                    Text(L10n.Explore.noResults)
                        .font(DS.Font.headline)
                        .foregroundStyle(.secondary)
                    Text("Không tìm thấy kết quả nào cho \"\(viewModel.searchText)\"")
                        .font(DS.Font.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowSeparator(.hidden)
                .padding(.top, DS.Spacing.xl)
            } else {
                ForEach(viewModel.searchResults) { user in
                    SearchResultRow(user: user)
                        .onTapGesture {
                            hideKeyboard()
                            AppRouter.shared.push(.userProfile(userId: user.id))
                        }
                }
            }
        }
        .listStyle(.plain)
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - ExploreGridItem

private struct ExploreGridItem: View {
    let post: Post
    let index: Int

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
                    InstagramIcon(.system(name: "square.on.square"), size: DS.Size.iconSmall, color: .white)
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
                    image.resizable().scaledToFill()
                } else {
                    Circle().fill(ColorTokens.buttonSecondary)
                }
            }
            .frame(width: DS.Size.avatarList, height: DS.Size.avatarList)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                HStack(spacing: DS.Spacing.xxs) {
                    Text(user.username)
                        .font(DS.Font.subheadlineBold)

                    if user.isVerified {
                        InstagramIcon(.verifiedBadge, size: DS.Size.iconXSmall, color: ColorTokens.accentPrimary)
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

// MARK: - Constants

private enum Constants {
    static let scrollThresholdTop: CGFloat = 10
}
