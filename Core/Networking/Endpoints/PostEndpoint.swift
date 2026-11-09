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
    // Cursor-based pagination (ISO timestamp cursor)
    case feed(cursor: String?, perPage: Int)
    case explore(cursor: String?, perPage: Int)
    case savedPosts(cursor: String?, perPage: Int)
    case userPosts(userId: String, cursor: String?, perPage: Int)
    case detail(id: String)
    case create(caption: String?, locationName: String?, locationLat: Double?, locationLng: Double?, media: [[String: Any]])
    case update(id: String, caption: String?, locationName: String?, locationLat: Double?, locationLng: Double?)
    case delete(id: String)
    case like(id: String)
    case unlike(id: String)
    case save(id: String)
    case unsave(id: String)
    case comments(postId: String, cursor: String?, perPage: Int)
    case addComment(postId: String, text: String, parentId: String?)

    var path: String {
        switch self {
        case .feed:                              return "/v1/posts/feed"
        case .explore:                           return "/v1/posts/explore"
        case .savedPosts:                        return "/v1/posts/saved"
        case .userPosts(let userId, _, _):       return "/v1/posts/user/\(userId)"
        case .detail(let id):                    return "/v1/posts/\(id)"
        case .create:                            return "/v1/posts"
        case .update(let id, _, _, _, _):        return "/v1/posts/\(id)"
        case .delete(let id):                    return "/v1/posts/\(id)"
        case .like(let id):                      return "/v1/posts/\(id)/like"
        case .unlike(let id):                    return "/v1/posts/\(id)/like"
        case .save(let id):                      return "/v1/posts/\(id)/save"
        case .unsave(let id):                    return "/v1/posts/\(id)/save"
        case .comments(let postId, _, _):        return "/v1/posts/\(postId)/comments"
        case .addComment(let postId, _, _):      return "/v1/posts/\(postId)/comments"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .feed, .explore, .savedPosts, .userPosts, .detail, .comments:
            return .get
        case .create, .like, .save, .addComment:
            return .post
        case .update:
            return .put
        case .delete, .unlike, .unsave:
            return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .feed(let cursor, let perPage),
             .explore(let cursor, let perPage),
             .savedPosts(let cursor, let perPage),
             .userPosts(_, let cursor, let perPage),
             .comments(_, let cursor, let perPage):
            var params: Parameters = ["perPage": perPage]
            if let cursor { params["cursor"] = cursor }
            return params
        case .create(let caption, let locationName, let locationLat, let locationLng, let media):
            var params: Parameters = ["media": media]
            if let caption { params["caption"] = caption }
            if let locationName { params["locationName"] = locationName }
            if let locationLat { params["locationLat"] = locationLat }
            if let locationLng { params["locationLng"] = locationLng }
            return params
        case .update(_, let caption, let locationName, let locationLat, let locationLng):
            // All fields optional; send only what's provided (partial update / PATCH-like semantics over PUT).
            var params: Parameters = [:]
            if let caption { params["caption"] = caption }
            if let locationName { params["locationName"] = locationName }
            if let locationLat { params["locationLat"] = locationLat }
            if let locationLng { params["locationLng"] = locationLng }
            return params
        case .addComment(_, let text, let parentId):
            var params: Parameters = ["text": text]
            if let parentId { params["parentId"] = parentId }
            return params
        case .detail, .delete, .like, .unlike, .save, .unsave:
            return nil
        }
    }
}
