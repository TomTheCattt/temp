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
    case userStory(userId: String)
    case create
    case markViewed(storyId: String)
    case delete(id: String)

    var path: String {
        switch self {
        case .feed:                     return "/v1/stories/feed"
        case .userStory(let userId):    return "/v1/users/\(userId)/stories"
        case .create:                   return "/v1/stories"
        case .markViewed(let storyId):  return "/v1/stories/\(storyId)/view"
        case .delete(let id):           return "/v1/stories/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .feed, .userStory:
            return .get
        case .create, .markViewed:
            return .post
        case .delete:
            return .delete
        }
    }
}
