//
//  FollowListView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - FollowListView

struct FollowListView: View {

    @State private var viewModel: FollowListViewModel

    init(viewModel: FollowListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if let errorMessage = viewModel.errorMessage, viewModel.users.isEmpty {
                ErrorStateView(
                    message: errorMessage,
                    retryAction: { Task { await viewModel.loadUsers() } }
                )
            } else if !viewModel.isLoading && viewModel.filteredUsers.isEmpty {
                EmptyStateView(
                    message: L10n.FollowList.empty,
                    icon: .people
                )
            } else {
                listContent
            }
        }
        .searchable(text: $viewModel.searchQuery, prompt: L10n.Common.search)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadUsers()
        }
        .task {
            await viewModel.loadUsers()
        }
    }

    private var listContent: some View {
        List {
            ForEach(viewModel.filteredUsers) { user in
                userRow(user)
                    .task {
                        if user.id == viewModel.filteredUsers.last?.id {
                            await viewModel.loadMore()
                        }
                    }
            }

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - User Row

    @ViewBuilder
    private func userRow(_ user: User) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            AsyncImage(url: user.avatarURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(ColorTokens.backgroundSubtler)
            }
            .frame(width: DS.Size.avatarList, height: DS.Size.avatarList)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                HStack(spacing: DS.Spacing.xxs) {
                    Text(user.username)
                        .font(DS.Font.username)
                    if user.isVerified {
                        InstagramIcon(.verifiedBadge, size: DS.Size.iconXSmall)
                    }
                }
                Text(user.fullName)
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Follow/Unfollow button (don't show for current user)
            if user.id != "user_current" {
                Button(action: {
                    Task { await viewModel.toggleFollow(for: user) }
                }) {
                    Text(user.isFollowing ? L10n.Common.following : L10n.Common.follow)
                        .font(DS.Font.captionBold)
                        .padding(.horizontal, DS.Spacing.md)
                        .padding(.vertical, DS.Spacing.iconGap)
                        .background(
                            user.isFollowing
                                ? ColorTokens.buttonSecondary
                                : ColorTokens.accentPrimary,
                            in: RoundedRectangle(cornerRadius: DS.Radius.medium)
                        )
                        .foregroundStyle(user.isFollowing ? Color.primary : .white)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            AppRouter.shared.push(.userProfile(userId: user.id))
        }
    }
}
