//
//  CloseFriendsViewModel.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import Foundation
import Observation

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

    private let closeFriendsUseCase: CloseFriendsUseCaseProtocol
    private var didLoad = false

    init(closeFriendsUseCase: CloseFriendsUseCaseProtocol) {
        self.closeFriendsUseCase = closeFriendsUseCase
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
            async let following = closeFriendsUseCase.fetchCandidates(currentUserId: currentUserId)
            async let existing = closeFriendsUseCase.fetchCloseFriends()

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
            let updated = try await closeFriendsUseCase.setCloseFriends(userIds: Array(closeFriendIds))
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
