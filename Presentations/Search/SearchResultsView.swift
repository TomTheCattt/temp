//
//  SearchResultsView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import NukeUI

// MARK: - SearchResultsView

struct SearchResultsView: View {

    @State private var viewModel: SearchResultsViewModel

    init(viewModel: SearchResultsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Active Search Bar Header
            searchHeader

            // Horizontal Tab picker
            tabPicker

            Divider()

            // Content
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, DS.Spacing.xxxl)
                    } else {
                        switch viewModel.selectedTab {
                        case .top:
                            topResults
                        case .accounts:
                            accountsResults
                        case .tags:
                            tagsResults
                        case .places:
                            placesResults
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                await viewModel.loadResults()
            }
        }
        .navigationTitle(L10n.Search.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadResults()
        }
    }

    // MARK: - Search Header

    private var searchHeader: some View {
        HStack(spacing: DS.Spacing.xs) {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(DS.Font.subheadline)
                    .foregroundStyle(.secondary)

                TextField(L10n.Common.search, text: $viewModel.query)
                    .textFieldStyle(.plain)
                    .font(DS.Font.subheadline)
                    .submitLabel(.search)
                    .onSubmit {
                        Task { await viewModel.loadResults() }
                    }

                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.query = ""
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
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.vertical, DS.Spacing.xs)
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.xs) {
                ForEach(SearchTab.allCases, id: \.self) { tab in
                    tabChip(tab)
                }
            }
            .padding(.horizontal, DS.Padding.horizontal)
            .padding(.vertical, DS.Spacing.xs)
        }
    }

    @ViewBuilder
    private func tabChip(_ tab: SearchTab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        Text(tabTitle(tab))
            .font(isSelected ? DS.Font.subheadlineBold : DS.Font.subheadline)
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.xs)
            .background(
                isSelected ? Color.primary : ColorTokens.buttonSecondary,
                in: Capsule()
            )
            .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
            .onTapGesture {
                withAnimation(DS.Animation.fast) {
                    viewModel.selectedTab = tab
                }
            }
    }

    private func tabTitle(_ tab: SearchTab) -> String {
        switch tab {
        case .top:      return L10n.Search.tabTop
        case .accounts: return L10n.Search.tabAccounts
        case .tags:     return L10n.Search.tabTags
        case .places:   return L10n.Search.tabPlaces
        }
    }

    // MARK: - Top Results

    private var topResults: some View {
        VStack(spacing: 0) {
            if viewModel.users.isEmpty && viewModel.posts.isEmpty {
                emptyStateView
            } else {
                // Top users section
                if !viewModel.users.isEmpty {
                    ForEach(viewModel.users.prefix(3)) { user in
                        userRow(user)
                    }
                }

                // Posts grid
                if !viewModel.posts.isEmpty {
                    postGrid
                }
            }
        }
    }

    // MARK: - Accounts Results

    private var accountsResults: some View {
        VStack(spacing: 0) {
            if viewModel.users.isEmpty {
                emptyStateView
            } else {
                ForEach(viewModel.users) { user in
                    userRow(user)
                }
            }
        }
    }

    // MARK: - Tags Results

    private var tagsResults: some View {
        VStack(spacing: DS.Spacing.sm) {
            if viewModel.tags.isEmpty {
                emptyStateView
            } else {
                ForEach(viewModel.tags) { tag in
                    HStack(spacing: DS.Spacing.sm) {
                        Circle()
                            .fill(ColorTokens.buttonSecondary)
                            .frame(width: DS.Size.avatarList, height: DS.Size.avatarList)
                            .overlay {
                                Text("#")
                                    .font(DS.Font.headline)
                                    .foregroundStyle(.secondary)
                            }

                        VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                            Text("#\(tag.name)")
                                .font(DS.Font.username)

                            Text("\(tag.postCount.formatted()) bài viết")
                                .font(DS.Font.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, DS.Padding.horizontal)
                    .padding(.vertical, DS.Spacing.xxs)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                        AppRouter.shared.push(.hashtag(name: tag.name))
                    }
                }
            }
        }
        .padding(.top, DS.Spacing.xs)
    }

    // MARK: - Places Results

    private var placesResults: some View {
        VStack(spacing: DS.Spacing.sm) {
            if viewModel.places.isEmpty {
                emptyStateView
            } else {
                ForEach(viewModel.places) { place in
                    HStack(spacing: DS.Spacing.sm) {
                        Circle()
                            .fill(ColorTokens.buttonSecondary)
                            .frame(width: DS.Size.avatarList, height: DS.Size.avatarList)
                            .overlay {
                                Image(systemName: "mappin.circle.fill")
                                    .font(DS.Font.title3)
                                    .foregroundStyle(.secondary)
                            }

                        VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                            Text(place.name)
                                .font(DS.Font.username)

                            Text(place.subtitle)
                                .font(DS.Font.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, DS.Padding.horizontal)
                    .padding(.vertical, DS.Spacing.xxs)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                        AppRouter.shared.push(.location(name: place.name))
                    }
                }
            }
        }
        .padding(.top, DS.Spacing.xs)
    }

    // MARK: - User Row

    @ViewBuilder
    private func userRow(_ user: User) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            LazyImage(url: user.avatarURL) { state in
                if let image = state.image {
                    image.resizable().scaledToFill()
                } else {
                    Circle().fill(ColorTokens.backgroundSubtler)
                }
            }
            .frame(width: DS.Size.avatarList, height: DS.Size.avatarList)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                HStack(spacing: DS.Spacing.xxs) {
                    Text(user.username)
                        .font(DS.Font.username)

                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(DS.Font.caption)
                            .foregroundStyle(ColorTokens.accentPrimary)
                    }
                }

                Text(user.fullName)
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.vertical, DS.Spacing.iconGap)
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
            AppRouter.shared.push(.userProfile(userId: user.id))
        }
    }

    // MARK: - Post Grid

    private var postGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: DS.Size.gridSpacing),
            GridItem(.flexible(), spacing: DS.Size.gridSpacing),
            GridItem(.flexible(), spacing: DS.Size.gridSpacing)
        ], spacing: DS.Size.gridSpacing) {
            ForEach(viewModel.posts) { post in
                if let media = post.mediaItems.first {
                    LazyImage(url: media.thumbnailURL ?? media.url) { state in
                        if let image = state.image {
                            image.resizable().aspectRatio(1, contentMode: .fill)
                        } else {
                            Rectangle().fill(ColorTokens.backgroundSubtler)
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
                    .onTapGesture {
                        hideKeyboard()
                        AppRouter.shared.push(.postDetail(postId: post.id))
                    }
                }
            }
        }
        .padding(.top, DS.Spacing.xs)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: DS.Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
                .padding(.bottom, DS.Spacing.xxs)

            Text(L10n.Search.noResults)
                .font(DS.Font.headline)
                .foregroundStyle(.secondary)

            Text("Không tìm thấy kết quả nào cho \"\(viewModel.query)\"")
                .font(DS.Font.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DS.Spacing.xxxl)
        .padding(.bottom, DS.Spacing.xxxl)
    }
}
