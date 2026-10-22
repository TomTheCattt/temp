//
//  AppNotifications.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import Foundation

extension Notification.Name {
    /// Dispatched when a new post is successfully created and published.
    /// `object` contains the newly created `Post`.
    nonisolated static let didCreatePost = Notification.Name("com.instagram.didCreatePost")

    /// Dispatched when a new story is successfully created and published.
    /// `object` contains the newly created `Story`.
    nonisolated static let didCreateStory = Notification.Name("com.instagram.didCreateStory")

    /// Dispatched when a story is viewed.
    /// `object` contains the `storyId` (String).
    nonisolated static let didUpdateStoryViewed = Notification.Name("com.instagram.didUpdateStoryViewed")

    /// Dispatched when current user profile is updated.
    /// `object` contains the updated `User`.
    nonisolated static let didUpdateProfile = Notification.Name("com.instagram.didUpdateProfile")

    /// Dispatched when a new message is received or sent.
    /// `object` contains the updated `Message`.
    nonisolated static let didUpdateMessage = Notification.Name("com.instagram.didUpdateMessage")

    /// Dispatched when conversations list, ordering, or unread count is updated.
    nonisolated static let didUpdateConversations = Notification.Name("com.instagram.didUpdateConversations")

    /// Dispatched when typing status changes in a conversation.
    /// `userInfo` contains `["conversationId": String, "userId": String, "isTyping": Bool]`.
    nonisolated static let didUpdateTypingStatus = Notification.Name("com.instagram.didUpdateTypingStatus")

    /// Dispatched when user block/unblock status changes.
    /// `userInfo` contains `["userId": String, "isBlocked": Bool]`.
    nonisolated static let didUpdateBlockStatus = Notification.Name("com.instagram.didUpdateBlockStatus")

    /// Dispatched when a call ends, used to record call logs into chat.
    /// `userInfo` contains `["remoteUserId": String, "hasVideo": Bool, "duration": String, "reason": String]`.
    nonisolated static let didEndCall = Notification.Name("com.instagram.didEndCall")
}
