//
//  NotificationPreferencesViewModel.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Observation

// MARK: - NotificationPreferencesViewModel

@MainActor
@Observable
final class NotificationPreferencesViewModel {

    // MARK: - State
    var preferences: [String: Bool] = [:]
    var isLoading = false

    // MARK: - Dependencies
    private let userSettingsUseCase: UserSettingsUseCaseProtocol

    // MARK: - Init
    init(userSettingsUseCase: UserSettingsUseCaseProtocol) {
        self.userSettingsUseCase = userSettingsUseCase
    }

    // MARK: - Preference Categories
    enum PreferenceCategory {
        enum WhatYouSee: String, CaseIterable {
            case posts = "posts"
            case stories = "stories"
            case reels = "reels"
            case igtv = "igtv"
            case liveVideos = "live_videos"
            case shop = "shop"
            case fundraisers = "fundraisers"

            var key: String { rawValue }

            var title: String {
                switch self {
                case .posts: return "Posts"
                case .stories: return "Stories"
                case .reels: return "Reels"
                case .igtv: return "IGTV"
                case .liveVideos: return "Live Videos"
                case .shop: return "Shop"
                case .fundraisers: return "Fundraisers"
                }
            }

            var subtitle: String {
                switch self {
                case .posts: return "Get notified about new posts"
                case .stories: return "Get notified about new stories"
                case .reels: return "Get notified about new Reels"
                case .igtv: return "Get notified about new IGTV videos"
                case .liveVideos: return "Get notified when accounts go live"
                case .shop: return "Get notified about shop updates"
                case .fundraisers: return "Get notified about fundraisers"
                }
            }
        }

        enum Interactions: String, CaseIterable {
            case likes = "likes"
            case comments = "comments"
            case mentions = "mentions"
            case tags = "tags"
            case commentsOnYourComments = "comments_on_your_comments"

            var key: String { rawValue }

            var title: String {
                switch self {
                case .likes: return "Likes"
                case .comments: return "Comments"
                case .mentions: return "Mentions"
                case .tags: return "Tags"
                case .commentsOnYourComments: return "Comments on Your Comments"
                }
            }

            var subtitle: String {
                switch self {
                case .likes: return "When someone likes your post"
                case .comments: return "When someone comments on your post"
                case .mentions: return "When you're mentioned"
                case .tags: return "When you're tagged in a post"
                case .commentsOnYourComments: return "When someone replies to your comment"
                }
            }
        }

        enum MessagesCalls: String, CaseIterable {
            case directMessages = "direct_messages"
            case messageRequests = "message_requests"
            case videoChats = "video_chats"
            case audioCalls = "audio_calls"

            var key: String { rawValue }

            var title: String {
                switch self {
                case .directMessages: return "Direct Messages"
                case .messageRequests: return "Message Requests"
                case .videoChats: return "Video Chats"
                case .audioCalls: return "Audio Calls"
                }
            }

            var subtitle: String {
                switch self {
                case .directMessages: return "New messages from people you follow"
                case .messageRequests: return "Messages from people you don't follow"
                case .videoChats: return "Incoming video chat requests"
                case .audioCalls: return "Incoming audio call requests"
                }
            }
        }

        enum LiveIGTV: String, CaseIterable {
            case liveVideos = "live_videos"
            case igtv = "igtv"

            var key: String { rawValue }

            var title: String {
                switch self {
                case .liveVideos: return "Live Videos"
                case .igtv: return "IGTV"
                }
            }

            var subtitle: String {
                switch self {
                case .liveVideos: return "When accounts you follow go live"
                case .igtv: return "When accounts you follow post IGTV"
                }
            }
        }

        enum Other: String, CaseIterable {
            case newFollowers = "new_followers"
            case followRequests = "follow_requests"
            case acceptedFollowRequests = "accepted_follow_requests"
            case recommendations = "recommendations"
            case reminders = "reminders"
            case support = "support"
            case announcements = "announcements"

            var key: String { rawValue }

            var title: String {
                switch self {
                case .newFollowers: return "New Followers"
                case .followRequests: return "Follow Requests"
                case .acceptedFollowRequests: return "Accepted Follow Requests"
                case .recommendations: return "Recommendations"
                case .reminders: return "Reminders"
                case .support: return "Support Requests"
                case .announcements: return "Announcements"
                }
            }

            var subtitle: String {
                switch self {
                case .newFollowers: return "When someone follows you"
                case .followRequests: return "When someone requests to follow you"
                case .acceptedFollowRequests: return "When your follow request is accepted"
                case .recommendations: return "Account and content recommendations"
                case .reminders: return "Reminders to post or check the app"
                case .support: return "Updates on your support requests"
                case .announcements: return "Important updates from Instagram"
                }
            }
        }
    }

    // MARK: - Actions
    func loadPreferences() async {
        isLoading = true
        do {
            let settings = try await userSettingsUseCase.fetchSettings()
            preferences["posts"] = settings.pushEnabled
            preferences["stories"] = settings.pushEnabled
            preferences["reels"] = settings.pushEnabled
            preferences["likes"] = settings.likeNotifications
            preferences["comments"] = settings.commentNotifications
            preferences["direct_messages"] = settings.directMessageNotifications
            preferences["new_followers"] = settings.followNotifications
        } catch {
            // Handle error silently or show toast
        }
        isLoading = false
    }

    func updatePreference(key: String, value: Bool) {
        preferences[key] = value
        Task {
            let patch = UserSettingsPatch(
                language: nil,
                biometricEnabled: nil,
                pushEnabled: value,
                darkMode: nil
            )
            _ = try? await userSettingsUseCase.updateSettings(patch)
        }
    }
}
