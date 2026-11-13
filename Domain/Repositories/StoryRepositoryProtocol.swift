//
//  StoryRepositoryProtocol.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - StoryRepositoryProtocol

protocol StoryRepositoryProtocol: Sendable {

    /// Fetch stories for the home feed bar (users who have active stories).
    func fetchStories() async throws -> [Story]

    /// Fetch story items for a specific user.
    func fetchStoryItems(userId: String) async throws -> [StoryItem]

    /// Create a new story item.
    func createStory(mediaData: Data, type: StoryItem.MediaType, duration: TimeInterval) async throws -> Story

    /// Mark a story as viewed.
    func markViewed(storyId: String) async throws

    /// Delete a story.
    func deleteStory(id: String) async throws

    /// Fetch comments for a story (offset-based pagination).
    func fetchStoryComments(storyId: String, page: Int, perPage: Int) async throws -> (comments: [Comment], page: Int, perPage: Int, total: Int, hasMore: Bool)

    /// Add a comment to a story (use parentId for replies).
    func addStoryComment(storyId: String, text: String, parentId: String?) async throws -> Comment

    /// Delete a comment on a story.
    func deleteStoryComment(storyId: String, commentId: String) async throws

    /// Fetch replies for a story.
    func fetchStoryReplies(storyId: String) async throws -> StoryRepliesResult

    /// Reply to a story.
    func replyToStory(storyId: String, text: String) async throws -> StoryReply

    /// Delete a story reply.
    func deleteStoryReply(replyId: String) async throws

    /// Delete all story replies.
    func deleteAllStoryReplies(storyId: String) async throws

    /// Set story replies enabled/disabled.
    func setStoryRepliesEnabled(storyId: String, enabled: Bool) async throws
}

/// Result type for fetching story replies.
struct StoryRepliesResult: Sendable {
    let replies: [StoryReply]
    let isCurrentUserOwner: Bool
    let areRepliesEnabled: Bool
}
