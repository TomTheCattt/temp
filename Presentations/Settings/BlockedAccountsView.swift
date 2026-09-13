//
//  BlockedAccountsView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI
import NukeUI

// MARK: - BlockedAccountsViewModel

@MainActor
@Observable
final class BlockedAccountsViewModel {

    private(set) var users: [User] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var pendingUnblockIds: Set<String> = []

    private let userRepository: UserRepositoryProtocol
    private var didLoad = false

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func loadBlockedUsers(reset: Bool = false) async {
        guard !isLoading else { return }
        if didLoad && !reset { return }

        isLoading = true
        errorMessage = nil

        do {
            users = try await userRepository.fetchBlockedUsers(page: 1, perPage: 50)
            didLoad = true
        } catch {
            errorMessage = error.userMessage
        }

        isLoading = false
    }

    func unblock(_ user: User) async {
        guard !pendingUnblockIds.contains(user.id) else { return }
        pendingUnblockIds.insert(user.id)

        // Optimistic removal.
        let index = users.firstIndex(where: { $0.id == user.id })
        if let index { users.remove(at: index) }

        do {
            try await userRepository.unblock(userId: user.id)
        } catch {
            // Revert on failure.
            if let index { users.insert(user, at: min(index, users.count)) }
            ToastManager.shared.error(error.userMessage)
        }

        pendingUnblockIds.remove(user.id)
    }
}

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
                    .font(DS.Font.subheadline)
                    .fontWeight(.semibold)
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
                        .font(DS.Font.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(.borderless)
            .tint(ColorTokens.accentPrimary)
            .disabled(viewModel.pendingUnblockIds.contains(user.id))
        }
    }
}
