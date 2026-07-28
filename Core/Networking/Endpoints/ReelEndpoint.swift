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
    case feed(page: Int, perPage: Int)
    case userReels(userId: String, page: Int, perPage: Int)
    case create(caption: String?, audioTrackId: String?)
    case delete(id: String)
    case like(id: String)
    case unlike(id: String)
    case save(id: String)
    case unsave(id: String)

    var path: String {
        switch self {
        case .feed:                             return "/v1/reels/feed"
        case .userReels(let userId, _, _):      return "/v1/users/\(userId)/reels"
        case .create:                           return "/v1/reels"
        case .delete(let id):                   return "/v1/reels/\(id)"
        case .like(let id):                     return "/v1/reels/\(id)/like"
        case .unlike(let id):                   return "/v1/reels/\(id)/unlike"
        case .save(let id):                     return "/v1/reels/\(id)/save"
        case .unsave(let id):                   return "/v1/reels/\(id)/unsave"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .feed, .userReels:
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
             .userReels(_, let page, let perPage):
            return ["page": page, "per_page": perPage]
        case .create(let caption, let audioTrackId):
            var params: Parameters = [:]
            if let caption { params["caption"] = caption }
            if let audioTrackId { params["audio_track_id"] = audioTrackId }
            return params
        default:
            return nil
        }
    }
}
