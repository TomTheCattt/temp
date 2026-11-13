//
//  GroupChatCreateView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import NukeUI

// MARK: - GroupChatCreateView

struct GroupChatCreateView: View {

    @State private var viewModel = GroupChatCreateViewModel(
        groupChatUseCase: DIContainer.shared.resolve(GroupChatUseCaseProtocol.self)
    )
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                    .padding(.horizontal, DS.Padding.horizontal)
                    .padding(.vertical, DS.Spacing.sm)

                Divider()

                // Selected Users
                if !viewModel.selectedUsers.isEmpty {
                    selectedUsersBar
                        .padding(.horizontal, DS.Padding.horizontal)
                        .padding(.vertical, DS.Spacing.xs)
                    Divider()
                }

                // User List
                if viewModel.isLoading && viewModel.filteredUsers.isEmpty {
                    loadingView
                } else if viewModel.filteredUsers.isEmpty && !viewModel.searchQuery.isEmpty {
                    noResultsView
                } else {
                    userList
                }
            }
            .navigationTitle(L10n.GroupChat.createTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) {
                        dismiss()
                    }
                    .foregroundStyle(ColorTokens.accentPrimary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.next) {
                        Task {
                            await viewModel.createGroup()
                            if viewModel.isCreated {
                                dismiss()
                            }
                        }
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(viewModel.canCreate ? ColorTokens.accentPrimary : .secondary)
                    .disabled(!viewModel.canCreate)
                }
            }
            .background(.backgroundSecondary)
            .dismissKeyboardOnTap()
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: DS.Spacing.xs) {
            InstagramIcon(.search(), size: 14, color: .secondary)

            TextField(L10n.GroupChat.searchPlaceholder, text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(DS.Font.body)

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    InstagramIcon(.system(name: "xmark.circle.fill"), size: 14, color: .secondary)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .background(ColorTokens.backgroundSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.medium))
    }

    private var selectedUsersBar: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text(L10n.GroupChat.selectedUsers)
                .font(DS.Font.captionBold)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.xs) {
                    ForEach(viewModel.selectedUsers) { user in
                        SelectedUserBadge(user: user) {
                            viewModel.toggleUserSelection(user)
                        }
                    }
                }
            }
        }
    }

    private var userList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Suggested section
                if viewModel.searchQuery.isEmpty && !viewModel.suggestedUsers.isEmpty {
                    SectionHeader(title: L10n.GroupChat.suggested)
                        .padding(.horizontal, DS.Padding.horizontal)

                    ForEach(viewModel.suggestedUsers) { user in
                        UserSelectionRow(
                            user: user,
                            isSelected: viewModel.selectedUsers.contains(user)
                        ) {
                            viewModel.toggleUserSelection(user)
                        }
                    }
                }

                // Search results / All users
                if !viewModel.filteredUsers.isEmpty {
                    if viewModel.searchQuery.isEmpty {
                        SectionHeader(title: L10n.GroupChat.allUsers)
                            .padding(.horizontal, DS.Padding.horizontal)
                    }

                    ForEach(viewModel.filteredUsers) { user in
                        UserSelectionRow(
                            user: user,
                            isSelected: viewModel.selectedUsers.contains(user)
                        ) {
                            viewModel.toggleUserSelection(user)
                        }
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: DS.Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            Text(L10n.Common.loading)
                .font(DS.Font.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsView: some View {
        VStack(spacing: DS.Spacing.md) {
            InstagramIcon(.system(name: "person.2.slash"), size: 64, color: .secondary)
            Text(L10n.GroupChat.noResults)
                .font(DS.Font.headline)
                .foregroundStyle(.primary)
            Text(L10n.GroupChat.noResultsMessage)
                .font(DS.Font.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Padding.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Selected User Badge

private struct SelectedUserBadge: View {
    let user: User
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: DS.Spacing.xxs) {
            LazyImage(url: user.avatarURL) { state in
                if let image = state.image {
                    image.resizable().scaledToFill()
                } else {
                    Circle().fill(ColorTokens.buttonSecondary)
                }
            }
            .frame(width: 28, height: 28)
            .clipShape(Circle())

            Text(user.username)
                .font(DS.Font.caption)
                .lineLimit(1)

            Button(action: onRemove) {
                InstagramIcon(.close, size: 10, color: .secondary)
            }
        }
        .padding(.horizontal, DS.Spacing.sm)
        .padding(.vertical, DS.Spacing.xxs)
        .background(ColorTokens.accentPrimary.opacity(0.15), in: Capsule())
        .foregroundStyle(ColorTokens.accentPrimary)
    }
}

// MARK: - User Selection Row

private struct UserSelectionRow: View {
    let user: User
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DS.Spacing.md) {
                LazyImage(url: user.avatarURL) { state in
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    } else {
                        Circle().fill(ColorTokens.buttonSecondary)
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                    Text(user.fullName.isEmpty ? user.username : user.fullName)
                        .font(DS.Font.subheadline)
                        .foregroundStyle(.primary)
                    Text("@\(user.username)")
                        .font(DS.Font.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Checkmark or empty circle
                ZStack {
                    Circle()
                        .stroke(isSelected ? ColorTokens.accentPrimary : Color(UIColor.separator), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(ColorTokens.accentPrimary)
                    }
                }
            }
            .padding(.horizontal, DS.Padding.horizontal)
            .padding(.vertical, DS.Spacing.sm)
            .background(Color(.systemBackground))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(DS.Font.captionBold)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, DS.Spacing.xs)
    }
}

// MARK: - ViewModel


