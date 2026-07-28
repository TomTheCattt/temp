//
//  NotificationEndpoint.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation
import Alamofire

// MARK: - NotificationEndpoint

enum NotificationEndpoint: APIEndpoint {
    case list(page: Int, perPage: Int)
    case markRead(id: String)
    case markAllRead

    var path: String {
        switch self {
        case .list:                 return "/v1/notifications"
        case .markRead(let id):     return "/v1/notifications/\(id)/read"
        case .markAllRead:          return "/v1/notifications/read-all"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list:
            return .get
        case .markRead, .markAllRead:
            return .post
        }
    }

    var parameters: Parameters? {
        switch self {
        case .list(let page, let perPage):
            return ["page": page, "per_page": perPage]
        default:
            return nil
        }
    }
}
