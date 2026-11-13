//
//  BlockedAccountsViewModel.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import Foundation
import Observation

// MARK: - BlockedAccountsViewModel

@MainActor
@Observable
final class BlockedAccountsViewModel {

    private(set) var users: [User] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var pendingUnblockIds: Set<String> = []

    private let blockedAccountsUseCase: BlockedAccountsUseCaseProtocol
    private var didLoad = false

    init(blockedAccountsUseCase: BlockedAccountsUseCaseProtocol) {
        self.blockedAccountsUseCase = blockedAccountsUseCase
    }

    func loadBlockedUsers(reset: Bool = false) async {
        guard !isLoading else { return }
        if didLoad && !reset { return }

        isLoading = true
        errorMessage = nil

        do {
            users = try await blockedAccountsUseCase.fetchBlockedUsers(page: 1, perPage: 50)
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
            try await blockedAccountsUseCase.unblock(userId: user.id)
        } catch {
            // Revert on failure.
            if let index { users.insert(user, at: min(index, users.count)) }
            ToastManager.shared.error(error.userMessage)
        }

        pendingUnblockIds.remove(user.id)
    }
}
