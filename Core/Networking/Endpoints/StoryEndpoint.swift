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

    var path: String {
        switch self {
        case .feed:                         return "/v1/stories/feed"
        case .userItems(let userId):        return "/v1/stories/\(userId)/items"
        case .create:                       return "/v1/stories"
        case .markViewed(let storyId):      return "/v1/stories/\(storyId)/view"
        case .delete(let id):               return "/v1/stories/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .feed, .userItems:
            return .get
        case .create, .markViewed:
            return .post
        case .delete:
            return .delete
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
        default:
            return nil
        }
    }
}
