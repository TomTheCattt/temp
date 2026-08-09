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
    case reels
    case chat
    case explore
    case profile

    var id: Int { rawValue }

    var icon: String {
        switch self {
        case .feed:     return "house"
        case .reels:    return "play.square"
        case .chat:     return "paperplane"
        case .explore:  return "magnifyingglass"
        case .profile:  return "person.circle"
        }
    }

    var selectedIcon: String {
        switch self {
        case .feed:     return "house.fill"
        case .reels:    return "play.square.fill"
        case .chat:     return "paperplane.fill"
        case .explore:  return "magnifyingglass"
        case .profile:  return "person.circle.fill"
        }
    }

    var title: String {
        switch self {
        case .feed:     return "Home"
        case .reels:    return "Reels"
        case .chat:     return "Chat"
        case .explore:  return "Explore"
        case .profile:  return "Profile"
        }
    }
}

// MARK: - AppRoute

/// All navigatable routes in the app (push navigation).
enum AppRoute: Hashable {
    // Profile
    case userProfile(userId: String)
    case followers(userId: String)
    case following(userId: String)
    case settings

    // Settings Sub-screens
    case savedPosts
    case closeFriends
    case blockedAccounts
    case changePassword
    case twoFactorAuth
    case termsOfService
    case privacyPolicy
    case openSourceLicenses

    // Feed / Post
    case postDetail(postId: String)
    case comments(postId: String)
    case likes(postId: String)

    // Messages
    case directMessages
    case conversation(conversationId: String)

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
    case editProfile
    case sharePost(postId: String)
    case reportPost(postId: String)
    case editPost(postId: String)

    var id: String {
        switch self {
        case .createPost:             return "createPost"
        case .createStory:            return "createStory"
        case .createReel:             return "createReel"
        case .editProfile:            return "editProfile"
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
    case storyViewer(userId: String)
    case myStory

    var id: String {
        switch self {
        case .camera:               return "camera"
        case .mediaViewer(let url): return "media_\(url.absoluteString)"
        case .storyCamera:          return "storyCamera"
        case .storyViewer(let id):  return "storyViewer_\(id)"
        case .myStory:              return "myStory"
        }
    }
}
