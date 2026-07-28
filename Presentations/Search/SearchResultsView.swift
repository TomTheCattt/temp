//
//  SearchResultsView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - SearchResultsView

struct SearchResultsView: View {

    @State private var viewModel: SearchResultsViewModel

    init(viewModel: SearchResultsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.xs) {
                    ForEach(SearchTab.allCases, id: \.self) { tab in
                        tabChip(tab)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, DS.Spacing.xs)
            }

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
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadResults()
        }
    }

    // MARK: - Tab Chip

    @ViewBuilder
    private func tabChip(_ tab: SearchTab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        Text(tab.rawValue)
            .font(isSelected ? DS.Font.subheadlineBold : DS.Font.subheadline)
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.xs)
            .background(
                isSelected ? Color.primary : ColorTokens.buttonSecondary,
                in: Capsule()
            )
            .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
            .onTapGesture { viewModel.selectedTab = tab }
    }

    // MARK: - Top Results

    private var topResults: some View {
        VStack(spacing: 0) {
            // Users section
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

    // MARK: - Accounts Results

    private var accountsResults: some View {
        ForEach(viewModel.users) { user in
            userRow(user)
        }
    }

    // MARK: - Tags Results (Placeholder)

    private var tagsResults: some View {
        VStack(spacing: DS.Spacing.sm) {
            ForEach(0..<5, id: \.self) { i in
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
                        Text("#\(viewModel.query)\(i > 0 ? String(i) : "")")
                            .font(DS.Font.username)
                        Text("\(Int.random(in: 1000...100_000)) posts")
                            .font(DS.Font.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, DS.Spacing.xxs)
                .contentShape(Rectangle())
                .onTapGesture {
                    AppRouter.shared.push(.hashtag(name: "\(viewModel.query)\(i > 0 ? String(i) : "")"))
                }
            }
        }
        .padding(.top, DS.Spacing.xs)
    }

    // MARK: - Places Results (Placeholder)

    private var placesResults: some View {
        VStack(spacing: DS.Spacing.sm) {
            ForEach(0..<5, id: \.self) { i in
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
                        Text("Location \(i + 1)")
                            .font(DS.Font.username)
                        Text("City, Country")
                            .font(DS.Font.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, DS.Spacing.xxs)
                .contentShape(Rectangle())
                .onTapGesture {
                    AppRouter.shared.push(.location(name: "Location \(i + 1)"))
                }
            }
        }
        .padding(.top, DS.Spacing.xs)
    }

    // MARK: - User Row

    @ViewBuilder
    private func userRow(_ user: User) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            AsyncImage(url: user.avatarURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(Color.gray.opacity(DS.Opacity.low))
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
        .padding(.horizontal)
        .padding(.vertical, DS.Spacing.iconGap)
        .contentShape(Rectangle())
        .onTapGesture {
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
                    AsyncImage(url: media.thumbnailURL ?? media.url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.2))
                    }
                    .frame(minHeight: DS.Size.gridCellMinHeight)
                    .clipped()
                    .onTapGesture {
                        AppRouter.shared.push(.postDetail(postId: post.id))
                    }
                }
            }
        }
        .padding(.top, DS.Spacing.xs)
    }
}
