//
//  PostEndpoint.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation
import Alamofire

// MARK: - PostEndpoint

enum PostEndpoint: APIEndpoint {
    case feed(page: Int, perPage: Int)
    case explore(page: Int, perPage: Int)
    case savedPosts(page: Int, perPage: Int)
    case userPosts(userId: String, page: Int, perPage: Int)
    case detail(id: String)
    case create(caption: String?, locationName: String?, locationLat: Double?, locationLng: Double?, media: [[String: Any]])
    case delete(id: String)
    case like(id: String)
    case unlike(id: String)
    case save(id: String)
    case unsave(id: String)

    var path: String {
        switch self {
        case .feed:                             return "/v1/posts/feed"
        case .explore:                          return "/v1/posts/explore"
        case .savedPosts:                       return "/v1/posts/saved"
        case .userPosts(let userId, _, _):      return "/v1/posts/user/\(userId)"
        case .detail(let id):                   return "/v1/posts/\(id)"
        case .create:                           return "/v1/posts"
        case .delete(let id):                   return "/v1/posts/\(id)"
        case .like(let id):                     return "/v1/posts/\(id)/like"
        case .unlike(let id):                   return "/v1/posts/\(id)/like"
        case .save(let id):                     return "/v1/posts/\(id)/save"
        case .unsave(let id):                   return "/v1/posts/\(id)/save"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .feed, .explore, .savedPosts, .userPosts, .detail:
            return .get
        case .create, .like, .save:
            return .post
        case .delete, .unlike, .unsave:
            return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .feed(let page, let perPage),
             .explore(let page, let perPage),
             .savedPosts(let page, let perPage),
             .userPosts(_, let page, let perPage):
            return ["page": page, "perPage": perPage]
        case .create(let caption, let locationName, let locationLat, let locationLng, let media):
            var params: Parameters = ["media": media]
            if let caption { params["caption"] = caption }
            if let locationName { params["locationName"] = locationName }
            if let locationLat { params["locationLat"] = locationLat }
            if let locationLng { params["locationLng"] = locationLng }
            return params
        case .detail, .delete, .like, .unlike, .save, .unsave:
            return nil
        }
    }
}
