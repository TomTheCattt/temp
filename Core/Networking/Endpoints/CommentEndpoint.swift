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
    case replies(commentId: String, page: Int, perPage: Int)
    case add(postId: String, text: String, parentId: String?)
    case delete(id: String)
    case like(id: String)
    case unlike(id: String)

    var path: String {
        switch self {
        case .list(let postId, _, _):       return "/v1/posts/\(postId)/comments"
        case .replies(let commentId, _, _): return "/v1/comments/\(commentId)/replies"
        case .add(let postId, _, _):        return "/v1/posts/\(postId)/comments"
        case .delete(let id):               return "/v1/comments/\(id)"
        case .like(let id):                 return "/v1/comments/\(id)/like"
        case .unlike(let id):               return "/v1/comments/\(id)/unlike"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list, .replies:
            return .get
        case .add, .like, .unlike:
            return .post
        case .delete:
            return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .list(_, let page, let perPage),
             .replies(_, let page, let perPage):
            return ["page": page, "per_page": perPage]
        case .add(_, let text, let parentId):
            var params: Parameters = ["text": text]
            if let parentId { params["parent_id"] = parentId }
            return params
        default:
            return nil
        }
    }
}
