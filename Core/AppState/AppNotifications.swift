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
}
