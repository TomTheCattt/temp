//
//  StoryEndpoint.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation
import Alamofire

// MARK: - StoryEndpoint

enum StoryEndpoint: APIEndpoint {
    case feed
    case userItems(userId: String)
    case create(mediaUrl: String, type: String, duration: Double, stickerType: String?, stickerData: String?)
    case markViewed(storyId: String)
    case delete(id: String)
    // Comments (offset-based pagination)
    case comments(storyId: String, page: Int, perPage: Int)
    case addComment(storyId: String, text: String, parentId: String?)
    case deleteComment(storyId: String, commentId: String)
    // Replies
    case fetchReplies(storyId: String)
    case addReply(storyId: String, text: String)
    case deleteReply(replyId: String)
    case deleteAllReplies(storyId: String)
    case setRepliesEnabled(storyId: String, enabled: Bool)

    var path: String {
        switch self {
        case .feed:                         return "/v1/stories/feed"
        case .userItems(let userId):        return "/v1/stories/\(userId)/items"
        case .create:                       return "/v1/stories"
        case .markViewed(let storyId):      return "/v1/stories/\(storyId)/view"
        case .delete(let id):               return "/v1/stories/\(id)"
        case .comments(let storyId, _, _):  return "/v1/stories/\(storyId)/comments"
        case .addComment(let storyId, _, _): return "/v1/stories/\(storyId)/comments"
        case .deleteComment(let storyId, let commentId): return "/v1/stories/\(storyId)/comments/\(commentId)"
        case .fetchReplies(let storyId):    return "/v1/stories/\(storyId)/replies"
        case .addReply(let storyId, _):     return "/v1/stories/\(storyId)/replies"
        case .deleteReply(let replyId):     return "/v1/stories/replies/\(replyId)"
        case .deleteAllReplies(let storyId): return "/v1/stories/\(storyId)/replies"
        case .setRepliesEnabled(let storyId, _): return "/v1/stories/\(storyId)/replies/enabled"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .feed, .userItems, .comments, .fetchReplies:
            return .get
        case .create, .markViewed, .addComment, .addReply:
            return .post
        case .delete, .deleteComment, .deleteReply, .deleteAllReplies:
            return .delete
        case .setRepliesEnabled:
            return .patch
        }
    }

    var parameters: Parameters? {
        switch self {
        case .create(let mediaUrl, let type, let duration, let stickerType, let stickerData):
            var params: Parameters = [
                "mediaUrl": mediaUrl,
                "type": type,
                "duration": duration
            ]
            if let stickerType { params["stickerType"] = stickerType }
            if let stickerData { params["stickerData"] = stickerData }
            return params
        case .comments(_, let page, let perPage):
            return ["page": page, "perPage": perPage]
        case .addComment(_, let text, let parentId):
            var params: Parameters = ["text": text]
            if let parentId { params["parentId"] = parentId }
            return params
        case .addReply(_, let text):
            return ["text": text]
        case .setRepliesEnabled(_, let enabled):
            return ["enabled": enabled]
        default:
            return nil
        }
    }
}
