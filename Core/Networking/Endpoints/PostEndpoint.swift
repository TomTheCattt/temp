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
    case userPosts(userId: String, page: Int, perPage: Int)
    case detail(id: String)
    case create(caption: String?, location: [String: Any]?)
    case delete(id: String)
    case like(id: String)
    case unlike(id: String)
    case save(id: String)
    case unsave(id: String)
    case savedPosts(page: Int, perPage: Int)
    case explore(page: Int, perPage: Int)
    case likes(postId: String, page: Int, perPage: Int)

    var path: String {
        switch self {
        case .feed:                     return "/v1/posts/feed"
        case .userPosts(let userId, _, _): return "/v1/users/\(userId)/posts"
        case .detail(let id):           return "/v1/posts/\(id)"
        case .create:                   return "/v1/posts"
        case .delete(let id):           return "/v1/posts/\(id)"
        case .like(let id):             return "/v1/posts/\(id)/like"
        case .unlike(let id):           return "/v1/posts/\(id)/unlike"
        case .save(let id):             return "/v1/posts/\(id)/save"
        case .unsave(let id):           return "/v1/posts/\(id)/unsave"
        case .savedPosts:               return "/v1/posts/saved"
        case .explore:                  return "/v1/posts/explore"
        case .likes(let postId, _, _):  return "/v1/posts/\(postId)/likes"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .feed, .userPosts, .detail, .savedPosts, .explore, .likes:
            return .get
        case .create, .like, .unlike, .save, .unsave:
            return .post
        case .delete:
            return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .feed(let page, let perPage),
             .userPosts(_, let page, let perPage),
             .savedPosts(let page, let perPage),
             .explore(let page, let perPage),
             .likes(_, let page, let perPage):
            return ["page": page, "per_page": perPage]
        case .create(let caption, let location):
            var params: Parameters = [:]
            if let caption { params["caption"] = caption }
            if let location { params["location"] = location }
            return params
        case .detail, .delete, .like, .unlike, .save, .unsave:
            return nil
        }
    }
}
