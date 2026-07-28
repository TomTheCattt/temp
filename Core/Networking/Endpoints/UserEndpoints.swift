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
    case updateProfile(name: String?, bio: String?, website: String?)
    case updateAvatar
    case search(query: String, page: Int, perPage: Int)
    case followers(userId: String, page: Int, perPage: Int)
    case following(userId: String, page: Int, perPage: Int)
    case follow(userId: String)
    case unfollow(userId: String)
    case block(userId: String)
    case unblock(userId: String)
    case suggested(page: Int, perPage: Int)

    var path: String {
        switch self {
        case .me:                               return "/v1/users/me"
        case .user(let id):                     return "/v1/users/\(id)"
        case .updateProfile:                    return "/v1/users/me"
        case .updateAvatar:                     return "/v1/users/me/avatar"
        case .search:                           return "/v1/users/search"
        case .followers(let userId, _, _):      return "/v1/users/\(userId)/followers"
        case .following(let userId, _, _):      return "/v1/users/\(userId)/following"
        case .follow(let userId):               return "/v1/users/\(userId)/follow"
        case .unfollow(let userId):             return "/v1/users/\(userId)/unfollow"
        case .block(let userId):                return "/v1/users/\(userId)/block"
        case .unblock(let userId):              return "/v1/users/\(userId)/unblock"
        case .suggested:                        return "/v1/users/suggested"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .me, .user, .search, .followers, .following, .suggested:
            return .get
        case .updateProfile:
            return .put
        case .updateAvatar, .follow, .unfollow, .block, .unblock:
            return .post
        }
    }

    var parameters: Parameters? {
        switch self {
        case .search(let query, let page, let perPage):
            return ["q": query, "page": page, "per_page": perPage]
        case .followers(_, let page, let perPage),
             .following(_, let page, let perPage),
             .suggested(let page, let perPage):
            return ["page": page, "per_page": perPage]
        case .updateProfile(let name, let bio, let website):
            var params: Parameters = [:]
            if let name { params["full_name"] = name }
            if let bio { params["bio"] = bio }
            if let website { params["website"] = website }
            return params
        default:
            return nil
        }
    }
}
