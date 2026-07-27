//
//  AppRoute.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - AppTab

enum AppTab: Int, CaseIterable, Identifiable {
    case feed
    case explore
    case reels
    case notifications
    case profile

    var id: Int { rawValue }

    var icon: String {
        switch self {
        case .feed:          return "house"
        case .explore:       return "magnifyingglass"
        case .reels:         return "play.square"
        case .notifications: return "heart"
        case .profile:       return "person.circle"
        }
    }

    var selectedIcon: String {
        switch self {
        case .feed:          return "house.fill"
        case .explore:       return "magnifyingglass"
        case .reels:         return "play.square.fill"
        case .notifications: return "heart.fill"
        case .profile:       return "person.circle.fill"
        }
    }

    var title: String {
        switch self {
        case .feed:          return "Home"
        case .explore:       return "Explore"
        case .reels:         return "Reels"
        case .notifications: return "Activity"
        case .profile:       return "Profile"
        }
    }
}

// MARK: - AppRoute

/// All navigatable routes in the app (push navigation).
enum AppRoute: Hashable {
    // Profile
    case userProfile(userId: String)
    case editProfile
    case followers(userId: String)
    case following(userId: String)
    case settings

    // Feed / Post
    case postDetail(postId: String)
    case comments(postId: String)
    case likes(postId: String)

    // Messages
    case directMessages
    case conversation(conversationId: String)

    // Stories
    case storyViewer(userId: String)

    // Explore
    case searchResults(query: String)
    case hashtag(name: String)
    case location(name: String)
}

// MARK: - AppSheet

/// Sheets presented modally.
enum AppSheet: Identifiable {
    case createPost
    case createStory
    case createReel
    case sharePost(postId: String)
    case reportPost(postId: String)
    case editPost(postId: String)

    var id: String {
        switch self {
        case .createPost:             return "createPost"
        case .createStory:            return "createStory"
        case .createReel:             return "createReel"
        case .sharePost(let id):      return "sharePost_\(id)"
        case .reportPost(let id):     return "reportPost_\(id)"
        case .editPost(let id):       return "editPost_\(id)"
        }
    }
}

// MARK: - AppFullScreen

/// Full-screen covers.
enum AppFullScreen: Identifiable {
    case camera
    case mediaViewer(url: URL)
    case storyCamera

    var id: String {
        switch self {
        case .camera:               return "camera"
        case .mediaViewer(let url): return "media_\(url.absoluteString)"
        case .storyCamera:          return "storyCamera"
        }
    }
}
