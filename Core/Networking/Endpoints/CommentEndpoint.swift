//
//  CommentEndpoint.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation
import Alamofire

// MARK: - CommentEndpoint

enum CommentEndpoint: APIEndpoint {
    case list(postId: String, page: Int, perPage: Int)
    case add(postId: String, text: String, parentId: String?)
    case delete(postId: String, commentId: String)
    case like(postId: String, commentId: String)
    case unlike(postId: String, commentId: String)

    var path: String {
        switch self {
        case .list(let postId, _, _):               return "/v1/posts/\(postId)/comments"
        case .add(let postId, _, _):                return "/v1/posts/\(postId)/comments"
        case .delete(let postId, let commentId):    return "/v1/posts/\(postId)/comments/\(commentId)"
        case .like(let postId, let commentId):      return "/v1/posts/\(postId)/comments/\(commentId)/like"
        case .unlike(let postId, let commentId):    return "/v1/posts/\(postId)/comments/\(commentId)/like"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list:
            return .get
        case .add, .like:
            return .post
        case .delete, .unlike:
            return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .list(_, let page, let perPage):
            return ["page": page, "perPage": perPage]
        case .add(_, let text, let parentId):
            var params: Parameters = ["text": text]
            if let parentId { params["parentId"] = parentId }
            return params
        default:
            return nil
        }
    }
}
