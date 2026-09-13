//
//  UserEndpoints.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation
import Alamofire

// MARK: - UserProfileEndpoint

enum UserProfileEndpoint: APIEndpoint {
    case me
    case user(id: String)
    case updateProfile(fullName: String?, bio: String?, website: String?, isPrivate: Bool?)
    case updateAvatar
    case search(query: String, page: Int, perPage: Int)
    case followers(userId: String, page: Int, perPage: Int)
    case following(userId: String, page: Int, perPage: Int)
    case follow(userId: String)
    case unfollow(userId: String)
    case block(userId: String)
    case unblock(userId: String)
    case blocked(page: Int, perPage: Int)
    case suggested(page: Int, perPage: Int)
    case settings
    case updateSettings(UserSettingsPatch)
    case closeFriends(page: Int, perPage: Int)
    case updateCloseFriends(userIds: [String])
    case registerDeviceToken(token: String, platform: String)
    case removeDeviceToken(token: String)

    var path: String {
        switch self {
        case .me, .updateProfile:               return "/v1/users/me"
        case .user(let id):                     return "/v1/users/\(id)"
        case .updateAvatar:                     return "/v1/upload/avatar"
        case .search:                           return "/v1/users/search"
        case .followers(let userId, _, _):      return "/v1/users/\(userId)/followers"
        case .following(let userId, _, _):      return "/v1/users/\(userId)/following"
        case .follow(let userId):               return "/v1/users/\(userId)/follow"
        case .unfollow(let userId):             return "/v1/users/\(userId)/follow"
        case .block(let userId):                return "/v1/users/\(userId)/block"
        case .unblock(let userId):              return "/v1/users/\(userId)/block"
        case .blocked:                          return "/v1/users/me/blocked"
        case .settings, .updateSettings:        return "/v1/users/me/settings"
        case .closeFriends, .updateCloseFriends: return "/v1/users/me/close-friends"
        case .suggested:                        return "/v1/users/suggested"
        case .registerDeviceToken:              return "/v1/users/me/device-token"
        case .removeDeviceToken:                return "/v1/users/me/device-token"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .me, .user, .search, .followers, .following, .suggested, .blocked,
             .settings, .closeFriends:
            return .get
        case .updateProfile, .updateSettings, .updateCloseFriends:
            return .put
        case .updateAvatar, .follow, .block, .registerDeviceToken:
            return .post
        case .unfollow, .unblock, .removeDeviceToken:
            return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .search(let query, let page, let perPage):
            return ["q": query, "page": page, "perPage": perPage]
        case .followers(_, let page, let perPage),
             .following(_, let page, let perPage),
             .blocked(let page, let perPage),
             .closeFriends(let page, let perPage),
             .suggested(let page, let perPage):
            return ["page": page, "perPage": perPage]
        case .updateProfile(let fullName, let bio, let website, let isPrivate):
            var params: Parameters = [:]
            if let fullName { params["fullName"] = fullName }
            if let bio { params["bio"] = bio }
            if let website { params["website"] = website }
            if let isPrivate { params["isPrivate"] = isPrivate }
            return params
        case .updateSettings(let patch):
            return patch.parameters
        case .updateCloseFriends(let userIds):
            return ["userIds": userIds]
        case .registerDeviceToken(let token, let platform):
            return ["token": token, "platform": platform]
        case .removeDeviceToken(let token):
            return ["token": token]
        default:
            return nil
        }
    }
}

// MARK: - UserSettingsPatch

/// Partial update payload for `PUT /v1/users/me/settings`.
/// Only non-nil fields are sent, matching the backend's optional-fields contract.
struct UserSettingsPatch: Sendable {
    var pushEnabled: Bool?
    var likeNotifications: Bool?
    var commentNotifications: Bool?
    var followNotifications: Bool?
    var directMessageNotifications: Bool?
    var activityStatusVisible: Bool?
    var highQualityUploads: Bool?
    var cellularDataEnabled: Bool?

    /// Convenience: patch representing the full settings object (all fields set).
    static func full(_ settings: UserSettings) -> UserSettingsPatch {
        UserSettingsPatch(
            pushEnabled: settings.pushEnabled,
            likeNotifications: settings.likeNotifications,
            commentNotifications: settings.commentNotifications,
            followNotifications: settings.followNotifications,
            directMessageNotifications: settings.directMessageNotifications,
            activityStatusVisible: settings.activityStatusVisible,
            highQualityUploads: settings.highQualityUploads,
            cellularDataEnabled: settings.cellularDataEnabled
        )
    }

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        if let pushEnabled { params["pushEnabled"] = pushEnabled }
        if let likeNotifications { params["likeNotifications"] = likeNotifications }
        if let commentNotifications { params["commentNotifications"] = commentNotifications }
        if let followNotifications { params["followNotifications"] = followNotifications }
        if let directMessageNotifications { params["directMessageNotifications"] = directMessageNotifications }
        if let activityStatusVisible { params["activityStatusVisible"] = activityStatusVisible }
        if let highQualityUploads { params["highQualityUploads"] = highQualityUploads }
        if let cellularDataEnabled { params["cellularDataEnabled"] = cellularDataEnabled }
        return params
    }
}
