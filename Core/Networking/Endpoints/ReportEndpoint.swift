//
//  ReportEndpoint.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Alamofire

// MARK: - ReportEndpoint

enum ReportEndpoint: APIEndpoint {
    // Create a report
    case create(
        type: ReportType,
        reason: ReportReason,
        description: String?,
        postId: String?,
        commentId: String?,
        reelId: String?,
        storyId: String?,
        userId: String?,
        messageId: String?
    )

    // Get current user's reports
    case myReports(page: Int, perPage: Int, status: ReportStatus?, type: ReportType?)

    // Get report details
    case detail(reportId: String)

    // Admin: Get all reports
    case allReports(page: Int, perPage: Int, status: ReportStatus?, type: ReportType?)

    // Admin: Update report status
    case updateStatus(reportId: String, status: ReportStatus, resolution: String?)

    var path: String {
        switch self {
        case .create:
            return "/v1/reports"
        case .myReports:
            return "/v1/reports/my"
        case .detail(let reportId):
            return "/v1/reports/\(reportId)"
        case .allReports:
            return "/v1/reports"
        case .updateStatus(let reportId, _, _):
            return "/v1/reports/\(reportId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create:
            return .post
        case .myReports, .detail, .allReports:
            return .get
        case .updateStatus:
            return .put
        }
    }

    var parameters: Parameters? {
        switch self {
        case .create(let type, let reason, let description, let postId, let commentId, let reelId, let storyId, let userId, let messageId):
            var params: Parameters = [
                "type": type.rawValue,
                "reason": reason.rawValue
            ]
            if let description { params["description"] = description }
            if let postId { params["postId"] = postId }
            if let commentId { params["commentId"] = commentId }
            if let reelId { params["reelId"] = reelId }
            if let storyId { params["storyId"] = storyId }
            if let userId { params["userId"] = userId }
            if let messageId { params["messageId"] = messageId }
            return params

        case .myReports(let page, let perPage, let status, let type),
             .allReports(let page, let perPage, let status, let type):
            var params: Parameters = ["page": page, "perPage": perPage]
            if let status { params["status"] = status.rawValue }
            if let type { params["type"] = type.rawValue }
            return params

        case .detail:
            return nil

        case .updateStatus(_, let status, let resolution):
            var params: Parameters = ["status": status.rawValue]
            if let resolution { params["resolution"] = resolution }
            return params
        }
    }
}

// Note: ReportType, ReportReason, ReportStatus are defined in Shared/Enums.swift