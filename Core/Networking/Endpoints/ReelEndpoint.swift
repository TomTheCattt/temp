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
    case create(videoUrl: String, thumbnailUrl: String?, caption: String?, duration: Double, audioName: String?, audioArtist: String?)
    case like(id: String)
    case unlike(id: String)
    case save(id: String)
    case unsave(id: String)
    case view(id: String)
    case delete(id: String)

    var path: String {
        switch self {
        case .feed:                     return "/v1/reels/feed"
        case .userReels(let userId, _, _): return "/v1/reels/user/\(userId)"
        case .create:                   return "/v1/reels"
        case .like(let id):             return "/v1/reels/\(id)/like"
        case .unlike(let id):           return "/v1/reels/\(id)/like"
        case .save(let id):             return "/v1/reels/\(id)/save"
        case .unsave(let id):           return "/v1/reels/\(id)/save"
        case .view(let id):             return "/v1/reels/\(id)/view"
        case .delete(let id):           return "/v1/reels/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .feed, .userReels:
            return .get
        case .create, .like, .save, .view:
            return .post
        case .unlike, .unsave, .delete:
            return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .feed(let page, let perPage):
            return ["page": page, "perPage": perPage]
        case .userReels(_, let page, let perPage):
            return ["page": page, "perPage": perPage]
        case .create(let videoUrl, let thumbnailUrl, let caption, let duration, let audioName, let audioArtist):
            var params: Parameters = [
                "videoUrl": videoUrl,
                "duration": duration
            ]
            if let thumbnailUrl { params["thumbnailUrl"] = thumbnailUrl }
            if let caption { params["caption"] = caption }
            if let audioName { params["audioName"] = audioName }
            if let audioArtist { params["audioArtist"] = audioArtist }
            return params
        default:
            return nil
        }
    }
}
