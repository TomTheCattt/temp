//
//  GroupChatDetailsViewModel.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation
import Observation
import UIKit

// MARK: - GroupChatDetailsViewModel

@MainActor
@Observable
final class GroupChatDetailsViewModel {

    // MARK: - State
    var groupName = ""
    var groupAvatarURL: URL?
    var members: [GroupMember] = []
    var adminIds: Set<String> = []
    var sharedMedia: [SharedMediaItem] = []
    var muteMessages = false
    var muteCalls = false
    var isLoading = false
    var errorMessage: String?

    var isAdmin: Bool {
        let currentUserId = SessionStore.shared.currentUserId
        guard !currentUserId.isEmpty else { return false }
        return adminIds.contains(currentUserId)
    }

    var memberCount: Int {
        members.count
    }

    // Alerts
    var showLeaveConfirmation = false
    var showDeleteConfirmation = false
    var showEditName = false
    var showAvatarPicker = false
    var showAddMembers = false

    // MARK: - Dependencies
    private let conversationId: String
    private let groupChatUseCase: GroupChatUseCaseProtocol

    // MARK: - Init
    init(conversationId: String, groupChatUseCase: GroupChatUseCaseProtocol) {
        self.conversationId = conversationId
        self.groupChatUseCase = groupChatUseCase
    }

    // MARK: - Actions
    func loadDetails() async {
        isLoading = true
        errorMessage = nil

        do {
            let details = try await groupChatUseCase.fetchDetails(id: conversationId)
            groupName = details.name ?? ""
            groupAvatarURL = details.avatarURL
            members = details.members
            adminIds = Set(details.adminIds)
            sharedMedia = details.sharedMedia
            muteMessages = details.muteMessages
            muteCalls = details.muteCalls
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func updateMuteMessages(_ value: Bool) async {
        do {
            try await groupChatUseCase.updateMuteSettings(id: conversationId, muteMessages: value, muteCalls: muteCalls)
        } catch {
            muteMessages.toggle()
            errorMessage = error.localizedDescription
        }
    }

    func updateMuteCalls(_ value: Bool) async {
        do {
            try await groupChatUseCase.updateMuteSettings(id: conversationId, muteMessages: muteMessages, muteCalls: value)
        } catch {
            muteCalls.toggle()
            errorMessage = error.localizedDescription
        }
    }

    func leaveGroup() async {
        do {
            try await groupChatUseCase.leaveGroup(id: conversationId)
            HapticFeedbackSafe.notification(.success)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteGroup() async {
        do {
            try await groupChatUseCase.deleteGroup(id: conversationId)
            HapticFeedbackSafe.notification(.success)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reportGroup() {
        // Show report flow
    }
}
