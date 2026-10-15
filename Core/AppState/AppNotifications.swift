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
    static let didCreatePost = Notification.Name("com.instagram.didCreatePost")

    /// Dispatched when a new story is successfully created and published.
    /// `object` contains the newly created `Story`.
    static let didCreateStory = Notification.Name("com.instagram.didCreateStory")

    /// Dispatched when current user profile is updated.
    /// `object` contains the updated `User`.
    static let didUpdateProfile = Notification.Name("com.instagram.didUpdateProfile")

    /// Dispatched when a new message is received or sent.
    /// `object` contains the updated `Message`.
    static let didUpdateMessage = Notification.Name("com.instagram.didUpdateMessage")

    /// Dispatched when conversations list, ordering, or unread count is updated.
    static let didUpdateConversations = Notification.Name("com.instagram.didUpdateConversations")

    /// Dispatched when typing status changes in a conversation.
    /// `userInfo` contains `["conversationId": String, "userId": String, "isTyping": Bool]`.
    static let didUpdateTypingStatus = Notification.Name("com.instagram.didUpdateTypingStatus")

    /// Dispatched when user block/unblock status changes.
    /// `userInfo` contains `["userId": String, "isBlocked": Bool]`.
    static let didUpdateBlockStatus = Notification.Name("com.instagram.didUpdateBlockStatus")

    /// Dispatched when a call ends, used to record call logs into chat.
    /// `userInfo` contains `["remoteUserId": String, "hasVideo": Bool, "duration": String, "reason": String]`.
    static let didEndCall = Notification.Name("com.instagram.didEndCall")
}
