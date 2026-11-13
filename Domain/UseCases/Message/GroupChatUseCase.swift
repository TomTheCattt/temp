//
//  GroupChatUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - GroupChatUseCase

protocol GroupChatUseCaseProtocol: Sendable {
    func createGroup(participantIds: [String], name: String?) async throws -> Conversation
    func fetchDetails(id: String) async throws -> GroupDetails
    func updateMuteSettings(id: String, muteMessages: Bool, muteCalls: Bool) async throws
    func leaveGroup(id: String) async throws
    func deleteGroup(id: String) async throws
}

final class GroupChatUseCase: GroupChatUseCaseProtocol, Sendable {

    private let messageRepository: MessageRepositoryProtocol

    init(messageRepository: MessageRepositoryProtocol) {
        self.messageRepository = messageRepository
    }

    func createGroup(participantIds: [String], name: String?) async throws -> Conversation {
        try await messageRepository.createGroupConversation(participantIds: participantIds, name: name)
    }

    func fetchDetails(id: String) async throws -> GroupDetails {
        try await messageRepository.fetchGroupDetails(id: id)
    }

    func updateMuteSettings(id: String, muteMessages: Bool, muteCalls: Bool) async throws {
        try await messageRepository.updateGroupMuteSettings(id: id, muteMessages: muteMessages, muteCalls: muteCalls)
    }

    func leaveGroup(id: String) async throws {
        try await messageRepository.leaveGroupConversation(id: id)
    }

    func deleteGroup(id: String) async throws {
        try await messageRepository.deleteGroupConversation(id: id)
    }
}
