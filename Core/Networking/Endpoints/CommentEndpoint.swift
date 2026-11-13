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
    // Post comments (offset-based pagination)
    case list(postId: String, page: Int, perPage: Int)
    case add(postId: String, text: String, parentId: String?)
    case delete(postId: String, commentId: String)

    // Reel comments (offset-based pagination)
    case listReelComments(reelId: String, page: Int, perPage: Int)
    case addReelComment(reelId: String, text: String, parentId: String?)
    case deleteReelComment(reelId: String, commentId: String)

    // Story comments (offset-based pagination)
    case listStoryComments(storyId: String, page: Int, perPage: Int)
    case addStoryComment(storyId: String, text: String, parentId: String?)
    case deleteStoryComment(storyId: String, commentId: String)

    var path: String {
        switch self {
        // Post comments
        case .list(let postId, _, _):               return "/v1/posts/\(postId)/comments"
        case .add(let postId, _, _):                return "/v1/posts/\(postId)/comments"
        case .delete(let postId, let commentId):    return "/v1/posts/\(postId)/comments/\(commentId)"
        // Reel comments
        case .listReelComments(let reelId, _, _):   return "/v1/reels/\(reelId)/comments"
        case .addReelComment(let reelId, _, _):     return "/v1/reels/\(reelId)/comments"
        case .deleteReelComment(let reelId, let commentId): return "/v1/reels/\(reelId)/comments/\(commentId)"
        // Story comments
        case .listStoryComments(let storyId, _, _):   return "/v1/stories/\(storyId)/comments"
        case .addStoryComment(let storyId, _, _):     return "/v1/stories/\(storyId)/comments"
        case .deleteStoryComment(let storyId, let commentId): return "/v1/stories/\(storyId)/comments/\(commentId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list, .listReelComments, .listStoryComments:
            return .get
        case .add, .addReelComment, .addStoryComment:
            return .post
        case .delete, .deleteReelComment, .deleteStoryComment:
            return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .list(_, let page, let perPage),
             .listReelComments(_, let page, let perPage),
             .listStoryComments(_, let page, let perPage):
            return ["page": page, "perPage": perPage]
        case .add(_, let text, let parentId),
             .addReelComment(_, let text, let parentId),
             .addStoryComment(_, let text, let parentId):
            var params: Parameters = ["text": text]
            if let parentId { params["parentId"] = parentId }
            return params
        default:
            return nil
        }
    }
}