//
//  ReelEndpoint.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation
import Alamofire

// MARK: - ReelEndpoint

enum ReelEndpoint: APIEndpoint {
    // Cursor-based pagination (ISO timestamp cursor) for feeds
    case feed(cursor: String?, perPage: Int)
    // Offset-based pagination (page/perPage) for user reels
    case userReels(userId: String, page: Int, perPage: Int)
    // Get single reel detail
    case detail(reelId: String)
    case create(videoUrl: String, thumbnailUrl: String?, caption: String?, duration: Double, audioName: String?, audioArtist: String?, audioCoverUrl: String?, isOriginalAudio: Bool?)
    case like(id: String)
    case unlike(id: String)
    case save(id: String)
    case unsave(id: String)
    case view(id: String)
    case delete(id: String)
    // Comments (offset-based pagination)
    case comments(reelId: String, page: Int, perPage: Int)
    case addComment(reelId: String, text: String, parentId: String?)
    case deleteComment(reelId: String, commentId: String)

    var path: String {
        switch self {
        case .feed:                      return "/v1/reels/feed"
        case .userReels(let userId, _, _): return "/v1/reels/user/\(userId)"
        case .detail(let reelId):        return "/v1/reels/\(reelId)"
        case .create:                    return "/v1/reels"
        case .like(let id):              return "/v1/reels/\(id)/like"
        case .unlike(let id):            return "/v1/reels/\(id)/like"
        case .save(let id):              return "/v1/reels/\(id)/save"
        case .unsave(let id):            return "/v1/reels/\(id)/save"
        case .view(let id):              return "/v1/reels/\(id)/view"
        case .delete(let id):            return "/v1/reels/\(id)"
        case .comments(let reelId, _, _): return "/v1/reels/\(reelId)/comments"
        case .addComment(let reelId, _, _): return "/v1/reels/\(reelId)/comments"
        case .deleteComment(let reelId, let commentId): return "/v1/reels/\(reelId)/comments/\(commentId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .feed, .userReels, .comments, .detail:
            return .get
        case .create, .like, .save, .view, .addComment:
            return .post
        case .unlike, .unsave, .delete, .deleteComment:
            return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .feed(let cursor, let perPage):
            var params: Parameters = ["perPage": perPage]
            if let cursor { params["cursor"] = cursor }
            return params
        case .detail:
            return nil
        case .userReels(_, let page, let perPage),
             .comments(_, let page, let perPage):
            return ["page": page, "perPage": perPage]
        case .create(let videoUrl, let thumbnailUrl, let caption, let duration, let audioName, let audioArtist, let audioCoverUrl, let isOriginalAudio):
            var params: Parameters = [
                "videoUrl": videoUrl,
                "duration": duration
            ]
            if let thumbnailUrl { params["thumbnailUrl"] = thumbnailUrl }
            if let caption { params["caption"] = caption }
            if let audioName { params["audioName"] = audioName }
            if let audioArtist { params["audioArtist"] = audioArtist }
            if let audioCoverUrl { params["audioCoverUrl"] = audioCoverUrl }
            if let isOriginalAudio { params["isOriginalAudio"] = isOriginalAudio }
            return params
        case .addComment(_, let text, let parentId):
            var params: Parameters = ["text": text]
            if let parentId { params["parentId"] = parentId }
            return params
        default:
            return nil
        }
    }
}
