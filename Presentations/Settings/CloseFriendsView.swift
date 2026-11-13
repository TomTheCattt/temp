//
//  CloseFriendsView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI
import NukeUI

// MARK: - CloseFriendsView

struct CloseFriendsView: View {

    @State private var viewModel: CloseFriendsViewModel
    @State private var searchText = ""

    init(viewModel: CloseFriendsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Text(L10n.Settings.closeFriendsFooter)
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            if viewModel.candidates.isEmpty {
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
                            retryAction: { Task { await viewModel.load(reset: true) } }
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ContentUnavailableView(
                            L10n.Settings.closeFriendsEmptyTitle,
                            systemImage: "star.circle",
                            description: Text(L10n.Settings.closeFriendsEmptyDescription)
                        )
                        .listRowBackground(Color.clear)
                    }
                }
            } else {
                Section(L10n.Settings.closeFriendsSuggestions) {
                    ForEach(viewModel.filtered(searchText)) { user in
                        candidateRow(user)
                    }
                }
            }
        }
        .navigationTitle(L10n.Settings.closeFriends)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: L10n.Common.search)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Button(L10n.Common.done) {
                        Task { await viewModel.save() }
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.hasUnsavedChanges)
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private func candidateRow(_ user: User) -> some View {
        let isSelected = viewModel.isCloseFriend(user)
        return HStack(spacing: DS.Spacing.md) {
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

            InstagramIcon(.system(name: isSelected ? "checkmark.circle.fill" : "circle"), size: DS.Size.iconDefault, color: isSelected ? ColorTokens.accentPrimary : Color(.systemGray3))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                viewModel.toggle(user)
            }
        }
    }
}
