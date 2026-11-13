//
//  ReportDTO.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation

// MARK: - Report Request DTOs

nonisolated struct CreateReportRequestDTO: Codable {
    let type: ReportTypeDTO
    let reason: ReportReasonDTO
    let description: String?
    let postId: String?
    let commentId: String?
    let reelId: String?
    let storyId: String?
    let userId: String?
    let messageId: String?
}

nonisolated struct UpdateReportStatusRequestDTO: Codable {
    let status: ReportStatusDTO
    let resolution: String?
}

// MARK: - Report Response DTOs

nonisolated struct ReportResponseDTO: Codable {
    let success: Bool
    let data: ReportDataDTO?
    let error: String?
    let message: String?
}

nonisolated struct ReportDataDTO: Codable {
    let report: ReportDTO
}

nonisolated struct ReportsListResponseDTO: Codable {
    let success: Bool
    let data: ReportsListDataDTO?
    let error: String?
    let message: String?
}

nonisolated struct ReportsListDataDTO: Codable {
    let items: [ReportDTO]
    let page: Int
    let perPage: Int
    let total: Int
    let hasMore: Bool
}

// MARK: - Report DTO

nonisolated struct ReportDTO: Codable {
    let id: String
    let reporterId: String
    let type: ReportTypeDTO
    let reason: ReportReasonDTO
    let description: String?
    let postId: String?
    let commentId: String?
    let reelId: String?
    let storyId: String?
    let userId: String?
    let messageId: String?
    let status: ReportStatusDTO
    let reviewedBy: String?
    let reviewedAt: Date?
    let resolution: String?
    let createdAt: Date
    let updatedAt: Date

    // Populated for admin list
    let reporter: ReporterDTO?
}

nonisolated struct ReporterDTO: Codable {
    let id: String
    let username: String
    let fullName: String
    let avatarUrl: String?
}

// MARK: - Report Enums

nonisolated enum ReportTypeDTO: String, Codable, CaseIterable {
    case post = "POST"
    case comment = "COMMENT"
    case reel = "REEL"
    case story = "STORY"
    case user = "USER"
    case message = "MESSAGE"

    var domainType: ReportType {
        switch self {
        case .post: return .post
        case .comment: return .comment
        case .reel: return .reel
        case .story: return .story
        case .user: return .user
        case .message: return .message
        }
    }
}

nonisolated enum ReportReasonDTO: String, Codable, CaseIterable {
    case spam = "SPAM"
    case inappropriateContent = "INAPPROPRIATE_CONTENT"
    case harassment = "HARASSMENT"
    case hateSpeech = "HATE_SPEECH"
    case violence = "VIOLENCE"
    case sexualContent = "SEXUAL_CONTENT"
    case selfHarm = "SELF_HARM"
    case fakeAccount = "FAKE_ACCOUNT"
    case intellectualProperty = "INTELLECTUAL_PROPERTY"
    case other = "OTHER"

    var domainReason: ReportReason {
        switch self {
        case .spam: return .spam
        case .inappropriateContent: return .inappropriateContent
        case .harassment: return .harassment
        case .hateSpeech: return .hateSpeech
        case .violence: return .violence
        case .sexualContent: return .sexualContent
        case .selfHarm: return .selfHarm
        case .fakeAccount: return .fakeAccount
        case .intellectualProperty: return .intellectualProperty
        case .other: return .other
        }
    }
}

nonisolated enum ReportStatusDTO: String, Codable, CaseIterable {
    case pending = "PENDING"
    case reviewed = "REVIEWED"
    case resolved = "RESOLVED"
    case dismissed = "DISMISSED"

    var domainStatus: ReportStatus {
        switch self {
        case .pending: return .pending
        case .reviewed: return .reviewed
        case .resolved: return .resolved
        case .dismissed: return .dismissed
        }
    }
}

// Import domain enums
// Note: ReportType, ReportReason, ReportStatus are defined in ReportEndpoint.swift
// They should be moved to a shared location or imported here