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
        static let yes = String(localized: "common.yes")
        static let no = String(localized: "common.no")

        /// Formatted "X likes" label (reused app-wide).
        static func likesCount(_ count: Int) -> String {
            String(format: String(localized: "common.likesCount"), count)
        }
    }

    // MARK: - Error (user-facing, friendly)

    enum Error {
        /// Generic fallback for unexpected/technical errors.
        static let generic = String(localized: "error.generic")
        /// No internet connection.
        static let offline = String(localized: "error.offline")
        /// Connection restored.
        static let backOnline = String(localized: "error.backOnline")
        /// Request timed out.
        static let timeout = String(localized: "error.timeout")
        /// Cannot reach the server.
        static let cannotReachServer = String(localized: "error.cannotReachServer")
        /// Server-side failure.
        static let server = String(localized: "error.server")
        /// Session expired (forced logout).
        static let sessionExpired = String(localized: "error.sessionExpired")
        /// Action not allowed.
        static let forbidden = String(localized: "error.forbidden")
        /// Resource not found.
        static let notFound = String(localized: "error.notFound")
        /// Generic title for error state views.
        static let title = String(localized: "error.title")
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
        static let invalidLogin = String(localized: "auth.invalidLogin")
        static let invalidRegister = String(localized: "auth.invalidRegister")

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
        static let emptyState = String(localized: "feed.emptyState")

        /// "View all N comments" link under a post.
        static func viewAllComments(_ count: Int) -> String {
            String(format: String(localized: "feed.viewAllComments"), count)
        }
    }

    // MARK: - Profile

    enum Profile {
        static let posts = String(localized: "profile.posts")
        static let followers = String(localized: "profile.followers")
        static let following = String(localized: "profile.following")
        static let editProfile = String(localized: "profile.editProfile")
        static let shareProfile = String(localized: "profile.shareProfile")
        static let unknownUser = String(localized: "profile.unknownUser")

        // Empty states
        static let noPostsTitle = String(localized: "profile.noPostsTitle")
        static let noPostsDescription = String(localized: "profile.noPostsDescription")
        static let noReelsTitle = String(localized: "profile.noReelsTitle")
        static let noReelsDescription = String(localized: "profile.noReelsDescription")
        static let noTaggedTitle = String(localized: "profile.noTaggedTitle")
        static let noTaggedDescription = String(localized: "profile.noTaggedDescription")
    }

    // MARK: - Edit Profile

    enum EditProfile {
        static let title = String(localized: "editProfile.title")
        static let changePhoto = String(localized: "editProfile.changePhoto")
        static let chooseFromLibrary = String(localized: "editProfile.chooseFromLibrary", defaultValue: "Choose from Library")
        static let removeCurrentPhoto = String(localized: "editProfile.removeCurrentPhoto", defaultValue: "Remove Current Photo")
        static let discardTitle = String(localized: "editProfile.discardTitle", defaultValue: "Discard changes?")
        static let discardConfirm = String(localized: "editProfile.discardConfirm", defaultValue: "Discard Changes")
        static let keepEditing = String(localized: "editProfile.keepEditing", defaultValue: "Keep Editing")
        static let name = String(localized: "editProfile.name")
        static let username = String(localized: "editProfile.username")
        static let website = String(localized: "editProfile.website")
        static let bio = String(localized: "editProfile.bio")

        static func bioCount(current: Int, max: Int) -> String {
            "\(current)/\(max)"
        }
    }

    // MARK: - Edit Post

    enum EditPost {
        static let title = String(localized: "editPost.title")
        static let caption = String(localized: "editPost.caption")
        static let captionPlaceholder = String(localized: "editPost.captionPlaceholder")
        static let location = String(localized: "editPost.location")
        static let locationPlaceholder = String(localized: "editPost.locationPlaceholder")
        static let discardTitle = String(localized: "editPost.discardTitle")
        static let discardConfirm = String(localized: "editPost.discardConfirm")
        static let keepEditing = String(localized: "editPost.keepEditing")
    }

    // MARK: - Comments

    enum Comments {
        static let title = String(localized: "comments.title")
        static let addComment = String(localized: "comments.addComment")
        static let replyPlaceholder = String(localized: "comments.replyPlaceholder")
        static let replyingTo = String(localized: "comments.replyingTo")
        static let empty = String(localized: "comments.empty")

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

    // MARK: - Create Menu

    enum CreateMenu {
        static let title = String(localized: "createMenu.title", defaultValue: "Tạo")
        static let post = String(localized: "createMenu.post", defaultValue: "Bài viết")
        static let reel = String(localized: "createMenu.reel", defaultValue: "Thước phim")
        static let story = String(localized: "createMenu.story", defaultValue: "Tin")
        static let live = String(localized: "createMenu.live", defaultValue: "Phát trực tiếp")
        static let liveNotAvailable = String(localized: "createMenu.liveNotAvailable", defaultValue: "Tính năng Phát trực tiếp sẽ sớm ra mắt.")
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
        static let camera = String(localized: "createPost.camera", defaultValue: "Máy ảnh")
        static let retake = String(localized: "createPost.retake", defaultValue: "Chụp lại")
        static let useMedia = String(localized: "createPost.useMedia", defaultValue: "Sử dụng")
        static let addSticker = String(localized: "createPost.addSticker", defaultValue: "Thêm ảnh / Sticker")
        static let createMode = String(localized: "createPost.createMode", defaultValue: "Tạo (Aa)")
        static let layoutMode = String(localized: "createPost.layoutMode", defaultValue: "Bố cục (Lưới)")
        static let audience = String(localized: "createPost.audience", defaultValue: "Đối tượng người xem")
        static let everyone = String(localized: "createPost.everyone", defaultValue: "Mọi người")
        static let closeFriends = String(localized: "createPost.closeFriends", defaultValue: "Bạn thân")
        static let advancedSettings = String(localized: "createPost.advancedSettings", defaultValue: "Cài đặt nâng cao")
        static let hideLikes = String(localized: "createPost.hideLikes", defaultValue: "Ẩn số lượt thích trên bài viết này")
        static let turnOffComments = String(localized: "createPost.turnOffComments", defaultValue: "Tắt tính năng bình luận")
        static let removeLocation = String(localized: "createPost.removeLocation", defaultValue: "Gỡ vị trí")
        static let editStudio = String(localized: "createPost.editStudio", defaultValue: "Chỉnh sửa")
        static let text = String(localized: "createPost.text", defaultValue: "Chữ")
        static let sticker = String(localized: "createPost.sticker", defaultValue: "Nhãn dán")
        static let draw = String(localized: "createPost.draw", defaultValue: "Vẽ")

        static func itemsSelected(_ count: Int) -> String {
            String(format: String(localized: "createPost.itemsSelected"), count)
        }
    }

    // MARK: - Create Reel

    enum CreateReel {
        static let title = String(localized: "createReel.title")
        static let addAudio = String(localized: "createReel.addAudio")
        static let videoPreview = String(localized: "createReel.videoPreview")
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

        // Saved posts
        static let savedEmptyTitle = String(localized: "settings.savedEmptyTitle")
        static let savedEmptyDescription = String(localized: "settings.savedEmptyDescription")

        // Blocked accounts
        static let blockedFooter = String(localized: "settings.blockedFooter")
        static let blockedEmptyTitle = String(localized: "settings.blockedEmptyTitle")
        static let blockedEmptyDescription = String(localized: "settings.blockedEmptyDescription")

        static let unblock = String(localized: "settings.unblock")
        static let cacheCleared = String(localized: "settings.cacheCleared")
        static let biometricUnavailable = String(localized: "settings.biometricUnavailable")
        static let biometricReason = String(localized: "settings.biometricReason")

        // Close friends
        static let closeFriendsFooter = String(localized: "settings.closeFriendsFooter")
        static let closeFriendsEmptyTitle = String(localized: "settings.closeFriendsEmptyTitle")
        static let closeFriendsEmptyDescription = String(localized: "settings.closeFriendsEmptyDescription")
        static let closeFriendsListTitle = String(localized: "settings.closeFriendsListTitle")
        static let closeFriendsSuggestions = String(localized: "settings.closeFriendsSuggestions")
        static let closeFriendsSaved = String(localized: "settings.closeFriendsSaved")
        static let add = String(localized: "settings.add")
        static let added = String(localized: "settings.added")
    }

    // MARK: - Change Password

    enum ChangePassword {
        static let title = String(localized: "changePassword.title")
        static let currentPassword = String(localized: "changePassword.currentPassword")
        static let newPassword = String(localized: "changePassword.newPassword")
        static let confirmNewPassword = String(localized: "changePassword.confirmNewPassword")
        static let requirementsFooter = String(localized: "changePassword.requirementsFooter")
        static let successTitle = String(localized: "changePassword.successTitle")
        static let successMessage = String(localized: "changePassword.successMessage")
    }

    // MARK: - Chat

    enum Chat {
        static let messagePlaceholder = String(localized: "chat.messagePlaceholder")
        static let statusSent = String(localized: "chat.statusSent")
        static let statusDelivered = String(localized: "chat.statusDelivered")
        static let statusRead = String(localized: "chat.statusRead")
        static let empty = String(localized: "chat.empty")
    }

    // MARK: - Reels

    enum Reels {
        static let empty = String(localized: "reels.empty")
    }

    // MARK: - Likes List

    enum LikesList {
        static let title = String(localized: "likesList.title")
        static let empty = String(localized: "likesList.empty")
    }

    // MARK: - Follow List

    enum FollowList {
        static let empty = String(localized: "followList.empty")
    }

    // MARK: - Tabs

    enum Tab {
        static let feed = String(localized: "tab.feed")
        static let explore = String(localized: "tab.explore")
        static let reels = String(localized: "tab.reels")
        static let chat = String(localized: "tab.chat")
        static let profile = String(localized: "tab.profile")
    }

    // MARK: - HUD (action feedback)

    /// Fallback status labels for the global action HUD (ProgressHUD).
    enum HUD {
        /// Generic success fallback (shown after a successful action when no custom message provided).
        static let success = String(localized: "hud.success")
        /// Generic error fallback (shown after a failed action when no custom message provided).
        static let error = String(localized: "hud.error")
        /// Loading label while publishing content.
        static let publishing = String(localized: "hud.publishing")
        /// Success label after publishing content.
        static let published = String(localized: "hud.published")
        /// Loading label while saving.
        static let saving = String(localized: "hud.saving")
        /// Success label after saving.
        static let saved = String(localized: "hud.saved")
        /// Loading label while logging out.
        static let loggingOut = String(localized: "hud.loggingOut")
    }

    // MARK: - Maintenance (global blocking screen)

    enum Maintenance {
        /// Screen title.
        static let title = String(localized: "maintenance.title")
        /// Friendly explanation body.
        static let message = String(localized: "maintenance.message")
        /// Retry button label.
        static let tryAgain = String(localized: "maintenance.tryAgain")
    }

    // MARK: - Force Update (global blocking screen)

    enum ForceUpdate {
        /// Screen title.
        static let title = String(localized: "forceUpdate.title")
        /// Friendly explanation body.
        static let message = String(localized: "forceUpdate.message")
        /// Update CTA button label.
        static let updateNow = String(localized: "forceUpdate.updateNow")
    }

    // MARK: - Explore

    enum Explore {
        static let noResults = String(localized: "explore.noResults")
    }

    // MARK: - Search

    enum Search {
        static let title = String(localized: "search.title")
        static let cityCountry = String(localized: "search.cityCountry")
        static let tabTop = String(localized: "search.tab.top", defaultValue: "Top")
        static let tabAccounts = String(localized: "search.tab.accounts", defaultValue: "Accounts")
        static let tabTags = String(localized: "search.tab.tags", defaultValue: "Tags")
        static let tabPlaces = String(localized: "search.tab.places", defaultValue: "Places")
        static let noResults = String(localized: "search.noResults", defaultValue: "No results found")

        static func locationName(_ index: Int) -> String {
            String(format: String(localized: "search.locationName"), index)
        }
    }

    // MARK: - Share Post

    enum SharePost {
        static let quickShare = String(localized: "sharePost.quickShare")
    }

    // MARK: - Media Viewer

    enum MediaViewer {
        static let videoPlayer = String(localized: "mediaViewer.videoPlayer")
        static let failedToLoad = String(localized: "mediaViewer.failedToLoad")
    }

    // MARK: - Story

    enum Story {
        static let yourStory = String(localized: "story.yourStory")
        static let viewers = String(localized: "story.viewers")
        static let closeFriends = String(localized: "story.closeFriends")
        static let deleteTitle = String(localized: "story.deleteTitle")
        static let deleteMessage = String(localized: "story.deleteMessage")
    }

    // MARK: - Story Camera

    enum StoryCamera {
        static let cameraPreview = String(localized: "storyCamera.cameraPreview")
        static let capturedPhoto = String(localized: "storyCamera.capturedPhoto")
        static let capturedVideo = String(localized: "storyCamera.capturedVideo")
        static let yourStory = String(localized: "storyCamera.yourStory")
        static let closeFriends = String(localized: "storyCamera.closeFriends")
        static let permissionTitle = String(localized: "storyCamera.permissionTitle")
        static let permissionMessage = String(localized: "storyCamera.permissionMessage")
        static let openSettings = String(localized: "storyCamera.openSettings")
    }

    // MARK: - Report Post

    enum ReportPost {
        static let title = String(localized: "reportPost.title")
        static let question = String(localized: "reportPost.question")
        static let submittedTitle = String(localized: "reportPost.submittedTitle")
        static let submittedMessage = String(localized: "reportPost.submittedMessage")
    }

    // MARK: - Call

    enum Call {
        static let remoteVideo = String(localized: "call.remoteVideo")
        static let you = String(localized: "call.you")
        static let calling = String(localized: "call.calling")
        static let ringing = String(localized: "call.ringing")
        static let incoming = String(localized: "call.incoming")
        static let connecting = String(localized: "call.connecting")
        static let reconnecting = String(localized: "call.reconnecting")
        static let ending = String(localized: "call.ending")
        static let videoCall = String(localized: "call.videoCall")
        static let audioCall = String(localized: "call.audioCall")
        static let mute = String(localized: "call.mute")
        static let speaker = String(localized: "call.speaker")
        static let flip = String(localized: "call.flip")
        static let ended = String(localized: "call.ended")
        static let declined = String(localized: "call.declined")
        static let busy = String(localized: "call.busy")
        static let noAnswer = String(localized: "call.noAnswer")
        static let failed = String(localized: "call.failed")
        static let cancelled = String(localized: "call.cancelled")
        static let cameraOff = String(localized: "call.cameraOff", defaultValue: "Tắt camera")
        static let camera = String(localized: "call.camera", defaultValue: "Camera")
        static let video = String(localized: "call.video", defaultValue: "Video")
        static let ongoingCall = String(localized: "call.ongoingCall", defaultValue: "Cuộc gọi đang diễn ra")
        static let returnToCall = String(localized: "call.returnToCall", defaultValue: "Chạm để quay lại cuộc gọi")
        static let alreadyInCall = String(localized: "call.alreadyInCall", defaultValue: "Bạn đang trong một cuộc gọi khác")
    }
}
