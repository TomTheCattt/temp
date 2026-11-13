//
//  BlockedAccountsView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI
import NukeUI

// MARK: - BlockedAccountsView

struct BlockedAccountsView: View {

    @State private var viewModel: BlockedAccountsViewModel

    init(viewModel: BlockedAccountsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Text(L10n.Settings.blockedFooter)
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            if viewModel.users.isEmpty {
                Section {
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    } else if let errorMessage = viewModel.errorMessage {
                        ErrorStateView(
                            message: errorMessage,
                            retryAction: { Task { await viewModel.loadBlockedUsers(reset: true) } }
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ContentUnavailableView(
                            L10n.Settings.blockedEmptyTitle,
                            systemImage: "nosign",
                            description: Text(L10n.Settings.blockedEmptyDescription)
                        )
                        .listRowBackground(Color.clear)
                    }
                }
            } else {
                Section {
                    ForEach(viewModel.users) { user in
                        blockedRow(user)
                    }
                }
            }
        }
        .navigationTitle(L10n.Settings.blockedAccounts)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadBlockedUsers()
        }
    }

    private func blockedRow(_ user: User) -> some View {
        HStack(spacing: DS.Spacing.md) {
            LazyImage(url: user.avatarURL) { state in
                if let image = state.image {
                    image.resizable()
                } else {
                    Circle().fill(ColorTokens.buttonSecondary)
                }
            }
            .frame(width: DS.Size.avatarCompact, height: DS.Size.avatarCompact)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                Text(user.username)
                    .font(DS.Font.subheadlineBold)
                Text(user.fullName)
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task { await viewModel.unblock(user) }
            } label: {
                if viewModel.pendingUnblockIds.contains(user.id) {
                    ProgressView()
                } else {
                    Text(L10n.Settings.unblock)
                        .font(DS.Font.subheadlineBold)
                }
            }
            .buttonStyle(.borderless)
            .tint(ColorTokens.accentPrimary)
            .disabled(viewModel.pendingUnblockIds.contains(user.id))
        }
    }
}
