//
//  StoryRepliesViewModel.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation
import Observation

// MARK: - StoryRepliesViewModel

@MainActor
@Observable
final class StoryRepliesViewModel {

    // MARK: - State
    var replies: [StoryReply] = []
    var isLoading = false
    var errorMessage: String?
    var replyText = ""
    var isStoryOwner = false
    var areRepliesEnabled = true

    // MARK: - Dependencies
    private let storyId: String
    private let storyRepliesUseCase: StoryRepliesUseCaseProtocol

    // MARK: - Init
    init(storyId: String, storyRepliesUseCase: StoryRepliesUseCaseProtocol) {
        self.storyId = storyId
        self.storyRepliesUseCase = storyRepliesUseCase
    }

    // MARK: - Computed
    var canSend: Bool {
        !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions
    func loadReplies() async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await storyRepliesUseCase.fetchReplies(storyId: storyId)
            replies = result.replies
            isStoryOwner = result.isCurrentUserOwner
            areRepliesEnabled = result.areRepliesEnabled
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func sendReply() async {
        guard canSend else { return }

        let text = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        replyText = ""

        do {
            let newReply = try await storyRepliesUseCase.replyToStory(storyId: storyId, text: text)
            replies.insert(newReply, at: 0)
        } catch {
            errorMessage = error.localizedDescription
            replyText = text // Restore on error
        }
    }

    func deleteReply(id: String) async {
        do {
            try await storyRepliesUseCase.deleteReply(replyId: id)
            replies.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAllReplies() async {
        do {
            try await storyRepliesUseCase.deleteAllReplies(storyId: storyId)
            replies.removeAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleRepliesEnabled() async {
        do {
            areRepliesEnabled.toggle()
            try await storyRepliesUseCase.setRepliesEnabled(storyId: storyId, enabled: areRepliesEnabled)
        } catch {
            areRepliesEnabled.toggle()
            errorMessage = error.localizedDescription
        }
    }
}
