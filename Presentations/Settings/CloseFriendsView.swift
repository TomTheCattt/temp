//
//  CloseFriendsView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI
import NukeUI

// MARK: - CloseFriendsViewModel

@MainActor
@Observable
final class CloseFriendsViewModel {

    /// All candidates (people the current user follows).
    private(set) var candidates: [User] = []
    /// IDs currently marked as close friends (working selection).
    private(set) var closeFriendIds: Set<String> = []
    private(set) var isLoading = false
    private(set) var isSaving = false
    private(set) var errorMessage: String?

    /// The last saved selection, used to detect unsaved changes.
    private var savedCloseFriendIds: Set<String> = []

    private let userRepository: UserRepositoryProtocol
    private var didLoad = false

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    /// True when the working selection differs from what's saved on the server.
    var hasUnsavedChanges: Bool {
        closeFriendIds != savedCloseFriendIds
    }

    func load(reset: Bool = false) async {
        guard !isLoading else { return }
        if didLoad && !reset { return }

        isLoading = true
        errorMessage = nil

        do {
            let currentUserId = SessionStore.shared.currentUserId
            // Load the candidate pool (following) and the current close-friends set
            // concurrently — they're independent reads.
            async let following = userRepository.fetchFollowing(
                userId: currentUserId,
                page: 1,
                perPage: 100
            )
            async let existing = userRepository.fetchCloseFriends(page: 1, perPage: 100)

            candidates = try await following
            let existingIds = Set(try await existing.map(\.id))
            closeFriendIds = existingIds
            savedCloseFriendIds = existingIds
            didLoad = true
        } catch {
            errorMessage = error.userMessage
        }

        isLoading = false
    }

    func isCloseFriend(_ user: User) -> Bool {
        closeFriendIds.contains(user.id)
    }

    func toggle(_ user: User) {
        if closeFriendIds.contains(user.id) {
            closeFriendIds.remove(user.id)
        } else {
            closeFriendIds.insert(user.id)
        }
    }

    /// Persists the current selection (full-set replace).
    func save() async {
        guard !isSaving, hasUnsavedChanges else { return }
        isSaving = true

        do {
            let updated = try await userRepository.setCloseFriends(userIds: Array(closeFriendIds))
            let updatedIds = Set(updated.map(\.id))
            closeFriendIds = updatedIds
            savedCloseFriendIds = updatedIds
            ToastManager.shared.success(L10n.Settings.closeFriendsSaved)
        } catch {
            ToastManager.shared.error(error.userMessage)
        }

        isSaving = false
    }

    func filtered(_ query: String) -> [User] {
        guard !query.isEmpty else { return candidates }
        let lowered = query.lowercased()
        return candidates.filter {
            $0.username.lowercased().contains(lowered) ||
            $0.fullName.lowercased().contains(lowered)
        }
    }
}

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
                    .font(DS.Font.subheadline)
                    .fontWeight(.semibold)
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
