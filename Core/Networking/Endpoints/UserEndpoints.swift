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
    case suggested(page: Int, perPage: Int)
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
        case .suggested:                        return "/v1/users/suggested"
        case .registerDeviceToken:              return "/v1/users/me/device-token"
        case .removeDeviceToken:                return "/v1/users/me/device-token"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .me, .user, .search, .followers, .following, .suggested:
            return .get
        case .updateProfile:
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
             .suggested(let page, let perPage):
            return ["page": page, "perPage": perPage]
        case .updateProfile(let fullName, let bio, let website, let isPrivate):
            var params: Parameters = [:]
            if let fullName { params["fullName"] = fullName }
            if let bio { params["bio"] = bio }
            if let website { params["website"] = website }
            if let isPrivate { params["isPrivate"] = isPrivate }
            return params
        case .registerDeviceToken(let token, let platform):
            return ["token": token, "platform": platform]
        case .removeDeviceToken(let token):
            return ["token": token]
        default:
            return nil
        }
    }
}
