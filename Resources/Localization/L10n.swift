//
//  L10n.swift
//  Instagram
//
//  Type-safe localization manager using String Catalogs (.xcstrings).
//  Provides compile-time organized access to all localized strings.
//
//  Usage:
//    Text(L10n.Auth.login)
//    Text(L10n.Comments.likesCount(42))
//

import Foundation

// MARK: - L10n

enum L10n {

    // MARK: - Common

    enum Common {
        static let cancel = String(localized: "common.cancel")
        static let done = String(localized: "common.done")
        static let ok = String(localized: "common.ok")
        static let error = String(localized: "common.error")
        static let loading = String(localized: "common.loading")
        static let retry = String(localized: "common.retry")
        static let save = String(localized: "common.save")
        static let delete = String(localized: "common.delete")
        static let share = String(localized: "common.share")
        static let next = String(localized: "common.next")
        static let back = String(localized: "common.back")
        static let search = String(localized: "common.search")
        static let post = String(localized: "common.post")
        static let follow = String(localized: "common.follow")
        static let following = String(localized: "common.following")
        static let unfollow = String(localized: "common.unfollow")
        static let message = String(localized: "common.message")
        static let reply = String(localized: "common.reply")
        static let send = String(localized: "common.send")
        static let sponsored = String(localized: "common.sponsored")
        static let sharedContent = String(localized: "common.sharedContent")
    }

    // MARK: - Auth

    enum Auth {
        static let login = String(localized: "auth.login")
        static let register = String(localized: "auth.register")
        static let logout = String(localized: "auth.logout")
        static let forgotPassword = String(localized: "auth.forgotPassword")
        static let createAccount = String(localized: "auth.createAccount")
        static let haveAccount = String(localized: "auth.haveAccount")
        static let logoutConfirmTitle = String(localized: "auth.logoutConfirmTitle")
        static let logoutConfirmMessage = String(localized: "auth.logoutConfirmMessage")

        enum Placeholder {
            static let usernameOrEmail = String(localized: "auth.placeholder.usernameOrEmail")
            static let password = String(localized: "auth.placeholder.password")
            static let confirmPassword = String(localized: "auth.placeholder.confirmPassword")
            static let fullName = String(localized: "auth.placeholder.fullName")
            static let email = String(localized: "auth.placeholder.email")
            static let phone = String(localized: "auth.placeholder.phone")
        }
    }

    // MARK: - Feed

    enum Feed {
        static let title = String(localized: "feed.title")
    }

    // MARK: - Profile

    enum Profile {
        static let posts = String(localized: "profile.posts")
        static let followers = String(localized: "profile.followers")
        static let following = String(localized: "profile.following")
        static let editProfile = String(localized: "profile.editProfile")
        static let shareProfile = String(localized: "profile.shareProfile")
    }

    // MARK: - Edit Profile

    enum EditProfile {
        static let title = String(localized: "editProfile.title")
        static let changePhoto = String(localized: "editProfile.changePhoto")
        static let name = String(localized: "editProfile.name")
        static let username = String(localized: "editProfile.username")
        static let website = String(localized: "editProfile.website")
        static let bio = String(localized: "editProfile.bio")

        static func bioCount(current: Int, max: Int) -> String {
            "\(current)/\(max)"
        }
    }

    // MARK: - Comments

    enum Comments {
        static let title = String(localized: "comments.title")
        static let addComment = String(localized: "comments.addComment")
        static let replyPlaceholder = String(localized: "comments.replyPlaceholder")
        static let replyingTo = String(localized: "comments.replyingTo")

        static func likesCount(_ count: Int) -> String {
            String(format: String(localized: "comments.likesCount"), count)
        }
    }

    // MARK: - Notifications

    enum Notifications {
        static let title = String(localized: "notifications.title")
        static let likedPost = String(localized: "notifications.likedPost")
        static let startedFollowing = String(localized: "notifications.startedFollowing")
        static let followRequest = String(localized: "notifications.followRequest")
        static let mentionedInPost = String(localized: "notifications.mentionedInPost")
        static let taggedInPost = String(localized: "notifications.taggedInPost")
        static let mentionedInStory = String(localized: "notifications.mentionedInStory")
        static let liveVideo = String(localized: "notifications.liveVideo")

        static func commented(_ text: String) -> String {
            String(format: String(localized: "notifications.commented"), text)
        }
    }

    // MARK: - Direct Messages

    enum DirectMessages {
        static let noMessages = String(localized: "directMessages.noMessages")
        static let sentPhoto = String(localized: "directMessages.sentPhoto")
        static let sentVideo = String(localized: "directMessages.sentVideo")
        static let sentVoice = String(localized: "directMessages.sentVoice")
        static let sharedPost = String(localized: "directMessages.sharedPost")
        static let sharedStory = String(localized: "directMessages.sharedStory")
        static let sharedReel = String(localized: "directMessages.sharedReel")
        static let you = String(localized: "directMessages.you")
    }

    // MARK: - Create Post

    enum CreatePost {
        static let title = String(localized: "createPost.title")
        static let filter = String(localized: "createPost.filter")
        static let selectMedia = String(localized: "createPost.selectMedia")
        static let selectFromLibrary = String(localized: "createPost.selectFromLibrary")
        static let captionPlaceholder = String(localized: "createPost.captionPlaceholder")
        static let addLocation = String(localized: "createPost.addLocation")
        static let tagPeople = String(localized: "createPost.tagPeople")
        static let alsoShareTo = String(localized: "createPost.alsoShareTo")

        static func itemsSelected(_ count: Int) -> String {
            String(format: String(localized: "createPost.itemsSelected"), count)
        }
    }

    // MARK: - Create Reel

    enum CreateReel {
        static let title = String(localized: "createReel.title")
        static let addAudio = String(localized: "createReel.addAudio")
    }

    // MARK: - Settings

    enum Settings {
        static let title = String(localized: "settings.title")
        static let account = String(localized: "settings.account")
        static let editProfile = String(localized: "settings.editProfile")
        static let saved = String(localized: "settings.saved")
        static let closeFriends = String(localized: "settings.closeFriends")
        static let blockedAccounts = String(localized: "settings.blockedAccounts")
        static let appearance = String(localized: "settings.appearance")
        static let theme = String(localized: "settings.theme")
        static let notifications = String(localized: "settings.notifications")
        static let pushNotifications = String(localized: "settings.pushNotifications")
        static let likes = String(localized: "settings.likes")
        static let comments = String(localized: "settings.comments")
        static let newFollowers = String(localized: "settings.newFollowers")
        static let directMessages = String(localized: "settings.directMessages")
        static let privacy = String(localized: "settings.privacy")
        static let privateAccount = String(localized: "settings.privateAccount")
        static let activityStatus = String(localized: "settings.activityStatus")
        static let security = String(localized: "settings.security")
        static let faceIdTouchId = String(localized: "settings.faceIdTouchId")
        static let password = String(localized: "settings.password")
        static let twoFactor = String(localized: "settings.twoFactor")
        static let dataStorage = String(localized: "settings.dataStorage")
        static let highQualityUploads = String(localized: "settings.highQualityUploads")
        static let useCellularData = String(localized: "settings.useCellularData")
        static let clearCache = String(localized: "settings.clearCache")
        static let about = String(localized: "settings.about")
        static let appVersion = String(localized: "settings.appVersion")
        static let termsOfService = String(localized: "settings.termsOfService")
        static let privacyPolicy = String(localized: "settings.privacyPolicy")
        static let openSourceLicenses = String(localized: "settings.openSourceLicenses")
        static let logOut = String(localized: "settings.logOut")
    }

    // MARK: - Chat

    enum Chat {
        static let messagePlaceholder = String(localized: "chat.messagePlaceholder")
        static let statusSent = String(localized: "chat.statusSent")
        static let statusDelivered = String(localized: "chat.statusDelivered")
        static let statusRead = String(localized: "chat.statusRead")
    }

    // MARK: - Tabs

    enum Tab {
        static let feed = String(localized: "tab.feed")
        static let explore = String(localized: "tab.explore")
        static let reels = String(localized: "tab.reels")
        static let notifications = String(localized: "tab.notifications")
        static let profile = String(localized: "tab.profile")
    }
}